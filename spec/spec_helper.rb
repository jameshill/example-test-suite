require 'yaml'
require 'json'
require "buildkite/test_collector"

Buildkite::TestCollector.configure(
  hook: :rspec,
  # url: "http://analytics-api.buildkite.localhost/v1/uploads",
  token: ENV["BUILDKITE_ANALYTICS_TOKEN"],
  env: {
    build_id: ENV["BUILDKITE_BUILD_ID"],
    step_id: ENV["BUILDKITE_STEP_ID"],
  }
)

REFERENCE_TIME = Time.new(2024, 11, 27, 0, 0, 0).to_i
DURATION_MULTIPLIER = 1 + (Time.now.utc.to_i - REFERENCE_TIME)/604800 # should double every 7 days-ish
puts "DURATION_MULTIPLIER = #{DURATION_MULTIPLIER}"
