require 'yaml'
require 'json'
require "buildkite/test_collector"
require "active_support"

def get_aws_execution_tags
  Aws::EC2Metadata.new(retries: 0, http_open_timeout: 0.01, http_read_timeout: 0.01)
    .get("/latest/dynamic/instance-identity/document")
    .then { JSON.parse(_1) }
    .then do |doc|
      {
        arch: doc["architecture"],
        region: doc["region"],
        instance_type: doc["instanceType"]
      }
    end
rescue
end

Buildkite::TestCollector.configure(
  hook: :rspec,
  # url: "http://analytics-api.buildkite.localhost/v1/uploads",
  token: ENV["BUILDKITE_ANALYTICS_TOKEN"],
  env: {
    build_id: ENV["BUILDKITE_BUILD_ID"],
    step_id: ENV["BUILDKITE_STEP_ID"],
    execution_tags: get_aws_execution_tags
  },
)

REFERENCE_TIME = Time.new(2024, 11, 27, 0, 0, 0).to_i
DURATION_MULTIPLIER = 1 + (Time.now.utc.to_i - REFERENCE_TIME)/604800 # should double every 7 days-ish
puts "DURATION_MULTIPLIER = #{DURATION_MULTIPLIER}"
