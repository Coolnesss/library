# Production image. Build it with Kamal, not by hand:
#   kamal deploy
ARG RUBY_VERSION=3.2.11
FROM ruby:$RUBY_VERSION-slim-bookworm AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    RACK_ENV="production" \
    RAILS_SERVE_STATIC_FILES="1" \
    RAILS_LOG_TO_STDOUT="1" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"


# --- Build stage: gems and assets -------------------------------------------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git pkg-config libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

COPY . .

# config/environments/production.rb reads the Gmail settings with ENV.fetch at
# boot, so precompiling needs values for them. These are throwaway; the real
# ones are injected by Kamal at run time.
RUN SECRET_KEY_BASE_DUMMY=1 GMAIL_APP_USER=dummy GMAIL_APP_PASS=dummy \
    bundle exec rails assets:precompile


# --- Final image ------------------------------------------------------------
FROM base

# poppler-utils: CreateCoversJob renders page 1 of the PDF with pdftoppm.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      poppler-utils libsqlite3-0 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp storage && \
    chown -R rails:rails db log tmp storage
USER 1000:1000

# Runs db:prepare before the server starts, so a deploy applies new migrations.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]
