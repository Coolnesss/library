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

# nodejs is the JavaScript runtime CoffeeScript and Uglifier compile with.
# shared-mime-info is needed by mimemagic, a Paperclip dependency, which builds
# its tables from the freedesktop MIME database at install time.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git pkg-config libsqlite3-dev nodejs shared-mime-info && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

COPY . .

# config/environments/production.rb reads the S3 and Gmail settings with
# ENV.fetch at boot, so precompiling needs values for all of them. These are
# throwaway; the real ones are injected by Kamal at run time.
RUN SECRET_KEY_BASE=dummy \
    S3_BUCKET_NAME=dummy AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy \
    AWS_REGION=dummy S3_ENDPOINT=dummy \
    GMAIL_APP_USER=dummy GMAIL_APP_PASS=dummy \
    bundle exec rails assets:precompile


# --- Final image ------------------------------------------------------------
FROM base

# Assets are precompiled into the image and config.assets.compile is false, so
# nothing here needs a JavaScript runtime. Without this, requiring coffee-rails
# at boot makes ExecJS look for one and raise.
ENV EXECJS_RUNTIME="Disabled"

# imagemagick: Paperclip's cover processing. ghostscript: Grim renders page 1
# of the PDF. file: Paperclip detects content types with it. shared-mime-info:
# mimemagic reads the freedesktop MIME database at run time, not just at build.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      imagemagick ghostscript file libsqlite3-0 shared-mime-info && \
    rm -rf /var/lib/apt/lists/* && \
    # Debian forbids ImageMagick from reading PDFs. Grim shells out to
    # `convert`, so leaving this in place means covers silently never appear.
    sed -i '/rights="none" pattern="PDF"/d' /etc/ImageMagick-6/policy.xml

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp storage && \
    chown -R rails:rails db log tmp storage
USER 1000:1000

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
