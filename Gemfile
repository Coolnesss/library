source 'https://rubygems.org'
ruby '3.2.11'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails', '~> 5.2'
gem 'rails', '~> 8.1.0'
# Assets are served as they are, with digests; JavaScript comes in through import maps.
gem 'propshaft'
gem 'importmap-rails'
gem 'turbo-rails'
# Use sqlite3 as the database for Active Record, in every environment
gem 'sqlite3', '~> 2.1'
gem 'bootsnap', require: false
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'#, '~> 2.0'
# Origami needs rexml and matrix, neither of which is a default gem any more.
gem 'rexml'
gem 'matrix'
# bundle exec rake doc:rails generates the API under doc/api.
#gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'bcrypt'
#gem 'aws-sdk', '~> 2.3'
gem 'aws-sdk-s3'
gem 'will_paginate'#, '3.1.7'
gem 'isbn_validation'
gem 'email_validator'
gem 'puma'
# Active Job backend. Runs inside Puma through its plugin; see config/puma.rb.
gem 'solid_queue'
gem 'redcarpet'
gem 'origami'

group :development do
  gem 'web-console', '~> 4.2'
  gem 'pry-rails'
end

group :development, :test do
  gem 'binding_of_caller'
  # Call 'debugger' anywhere in the code to stop execution and get a console
  gem 'debug'
  gem 'better_errors'
end
