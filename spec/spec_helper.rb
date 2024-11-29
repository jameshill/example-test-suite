require 'yaml'
require 'json'
require "buildkite/test_collector"
require "active_support"

# Load the JSON from the environment variable
metadata_json = ENV['INSTANCE_METADATA_JSON']

# Check if the variable exists and parse it
if metadata_json.nil? || metadata_json.empty?
  puts "Environment variable INSTANCE_METADATA_JSON is not set or empty."
else
  begin
    # Parse the JSON string into a Ruby hash
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
