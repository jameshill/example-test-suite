require 'yaml'
require 'json'
require "buildkite/test_collector"
require "active_support"
require 'active_support/core_ext'
require "aws-sdk-core"

def get_aws_execution_tags
  Aws::EC2Metadata.new(retries: 0, http_open_timeout: 0.1, http_read_timeout: 0.1)
    .get("/latest/dynamic/instance-identity/document")
    .then { JSON.parse(_1) }
    .then do |doc|
      {
        "cloud.region" =>  doc["region"],
        "host.arch" => doc["architecture"],
        "host.type" => doc["instanceType"],
        "pipeline" => ENV["BUILDKITE_PIPELINE_SLUG"]
      }
    end
rescue => e
  $stderr.puts(e.inspect)
end

tags = get_aws_execution_tags || {}

if ENV["SPOOF_ARM_MODE"] == "true"
  tags["host.arch"] = "arm64"

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
  },
  tags: tags
)

REFERENCE_TIME = Time.new(2024, 11, 27, 0, 0, 0).to_i
DURATION_MULTIPLIER = (1 + (Time.now.utc.to_i - REFERENCE_TIME)/2419200.0) * duration_multiplier
FLAKY_MULTIPLIER = 1 * flaky_multiplier

puts "DURATION_MULTIPLIER = #{DURATION_MULTIPLIER}"
puts "FLAKY_MULTIPLIER = #{FLAKY_MULTIPLIER}"

def spoof_duration(type: :unit)
  case type
  when :e2e
    sleep(rand(45..55) * DURATION_MULTIPLIER)
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

def redact_non_deterministic_data(input)
  input = input.gsub(/#<\w+(::\w+)*(\s\w+:\s[^>]+)*>/, '{object}')
  input = input.gsub(/\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b/, '{uuid}')
  input = input.gsub(/\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?\b/, '{timestamp}')
  input = input.gsub(/\b\d{4}-\d{2}-\d{2}\b/, '{date}')
  input
end

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    # Override automatic descriptions in Buildkite to allow for better grouping of tests
    # because default descriptions with matchers will interpolate a pretty output of the object
    # which often contains random characters (e.g. prefixed tokens, Forgery timestamps, etc.)
    #
    # Only do this in Buildkite because local output from matchers is useful for development.
    if (ENV['BUILDKITE_BUILD_ID'] || "").present?
      # This is a conditional that only changes metadata if it's an example spec (e.g. `it do` block)
      if metadata.key?(:execution_result) && metadata.key?(:example_group) && metadata[:block].present?
        metadata[:description] = redact_non_deterministic_data(metadata[:description])
        puts metadata[:description]
      end
    end
  end
end
