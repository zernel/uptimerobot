ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

ActiveRecord.verify_foreign_keys_for_fixtures = false

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

    fixtures :all

    include Devise::Test::IntegrationHelpers
    include ActiveSupport::Testing::TimeHelpers
  end
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
