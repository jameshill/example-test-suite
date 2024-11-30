require 'yaml'
require 'json'
require "buildkite/test_collector"
require "active_support"
require "aws-sdk-core"

def get_aws_execution_tags
  Aws::EC2Metadata.new(retries: 0, http_open_timeout: 0.1, http_read_timeout: 0.1)
    .get("/latest/dynamic/instance-identity/document")
    .then { JSON.parse(_1) }
    .then do |doc|
      {
        arch: doc["architecture"],
        region: doc["region"],
        instance_type: doc["instanceType"]
      }
    end
rescue => e
  $stderr.puts(e.inspect)
end

execution_tags = get_aws_execution_tags || {}

if ENV["SPOOF_ARM_MODE"] == "true"
  execution_tags[:arch] = "arm64"

  duration_multiplier = 0.85
  # less flaky
  flaky_multiplier = 0.6
else
  duration_multiplier = 1
  flaky_multiplier = 1
end

Buildkite::TestCollector.configure(
  hook: :rspec,
  # url: "http://analytics-api.buildkite.localhost/v1/uploads",
  token: ENV["BUILDKITE_ANALYTICS_TOKEN"],
  env: {
    build_id: ENV["BUILDKITE_BUILD_ID"],
    step_id: ENV["BUILDKITE_STEP_ID"],
    execution_tags: execution_tags
  }
)

REFERENCE_TIME = Time.new(2024, 11, 27, 0, 0, 0).to_i
DURATION_MULTIPLIER = (1 + (Time.now.utc.to_i - REFERENCE_TIME)/2419200.0) * duration_multiplier
FLAKY_MULTIPLIER = 1 * flaky_multiplier

puts "DURATION_MULTIPLIER = #{DURATION_MULTIPLIER}"
puts "FLAKY_MULTIPLIER = #{FLAKY_MULTIPLIER}"

def spoof_duration(type: :unit)
  case type
  when :e2e
    sleep(45 * DURATION_MULTIPLIER)
  when :feature
    time = rand(1..3) * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep time.round(3)
  when :slow_feature
    time = rand(5..10) * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep time.round(3)
  when :really_slow_feature
    time = rand(10..30) * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep time.round(3)
  when :unit
    sleep(rand(0.1..0.3) * DURATION_MULTIPLIER)
  else
    sleep(rand(0.1..0.3) * DURATION_MULTIPLIER)
  end
end
