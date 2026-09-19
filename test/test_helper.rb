ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  # Every fixture user's password.
  PASSWORD = 'password'.freeze

  def sign_in(user, password: PASSWORD)
    post login_path, params: { email: user.email, password: password }
  end
end

# Uploads made by the tests; see paperclip_defaults in config/environments/test.rb.
Minitest.after_run { FileUtils.rm_rf(Rails.root.join('tmp', 'test_uploads')) }
