ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!

ActiveRecord.verify_foreign_keys_for_fixtures = false

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

    fixtures :all

    include Devise::Test::IntegrationHelpers
    include ActiveSupport::Testing::TimeHelpers
    include ActiveJob::TestHelper
  end
end
