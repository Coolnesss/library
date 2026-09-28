source 'https://rubygems.org'
ruby '3.2.11'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails', '~> 5.2'
gem 'rails', '~> 8.1.0'
# Rails 7 no longer pulls in Sprockets; it stays until the frontend moves to Propshaft.
gem 'sprockets-rails'
# Sprockets 3 calls ERB.new with positional arguments, which erb 6 removed.
gem 'erb', '< 6'
# Use sqlite3 as the database for Active Record, in every environment
gem 'sqlite3', '~> 2.1'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'bootsnap', require: false
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'#, '~> 2.0'
# Origami needs rexml and matrix, neither of which is a default gem any more.
gem 'rexml'
gem 'matrix'
gem 'ransack'
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
gem 'font_awesome5_rails'

group :development do
  gem 'web-console', '~> 4.2'
  gem 'pry-rails'
  gem 'rails_real_favicon'
end

group :development, :test do
  gem 'binding_of_caller'
  # Call 'debugger' anywhere in the code to stop execution and get a console
  gem 'debug'
  gem 'better_errors'
end
