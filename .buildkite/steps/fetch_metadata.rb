require 'net/http'
require 'json'

# Base URL for the EC2 Instance Metadata Service
BASE_URL = "http://169.254.169.254/latest/meta-data"

# Function to fetch metadata recursively
def fetch_metadata(path = "")
  uri = URI("#{BASE_URL}/#{path}")
  response = Net::HTTP.get(uri)

  # Check if response contains nested keys (directories)
  if response.include?("\n")
    result = {}
    response.split("\n").each do |line|
      if line.end_with?("/") # It's a directory
        key = line.chomp("/")
        result[key] = fetch_metadata("#{path}#{key}/")
      else # It's a key-value pair
        result[line] = fetch_metadata("#{path}#{line}")
      end
    end
    result
  else
    response # Scalar value
  end
end

# Fetch the full metadata and convert to JSON
metadata = fetch_metadata
puts JSON.pretty_generate(metadata)
