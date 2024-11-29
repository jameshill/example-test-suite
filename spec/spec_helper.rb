require 'yaml'
require 'json'
require "buildkite/test_collector"
require "active_support"

begin
  fetch_script_path = "./bin/fetch_metadata.rb"
  metadata_json = `ruby #{fetch_script_path}`
  # Parse the JSON output into a Ruby hash
  metadata = JSON.parse(metadata_json)

  # Access metadata as a hash
  puts "Parsed Metadata:"
  puts metadata

  # Example: Access specific keys
  puts "Instance Type: #{metadata['instance-type']}"
  puts "Instance ID: #{metadata['instance-id']}"
  puts "Instance Lifecycle: #{metadata['instance-life-cycle']}"
  puts "Instance AZ: #{metadata['availability-zone']}"
rescue JSON::ParserError => e
  puts "Failed to parse JSON: #{e.message}"
end

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
