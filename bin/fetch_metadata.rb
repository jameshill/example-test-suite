require 'net/http'
require 'json'

BASE_URL = "http://169.254.169.254/latest/meta-data"

def fetch_metadata(path = "")
  uri = URI("#{BASE_URL}/#{path}")
  response = Net::HTTP.get(uri)

  # If the response contains multiple lines, treat it as a directory
  if response.include?("\n")
    result = {}
    response.split("\n").each do |line|
      if line.end_with?("/") # Handle directory
        key = line.chomp("/") # Remove trailing slash
        result[key] = fetch_metadata("#{path}#{key}/")
      else # Handle scalar value
        result[line] = fetch_metadata("#{path}#{line}")
      end
    end
    result
  else
    response # Scalar value
  end
end

begin
  metadata = fetch_metadata
  puts JSON.pretty_generate(metadata)
rescue URI::InvalidURIError => e
  puts "Invalid URI encountered: #{e.message}"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
