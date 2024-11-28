#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'csv'

spec_files = Dir["spec/**/*.rb"]

# Define the URL and Bearer token
url = "https://api.buildkite.com/v2/analytics/organizations/test-engine-sandbox/suites/rspec-3/test_files"
bearer_token = ENV["API_ACCESS_TOKEN"]

if bearer_token.nil?
  puts "No API Access Token"
  return
end


uri = URI.parse(url)
request = Net::HTTP::Post.new(uri)
request["Authorization"] = "Bearer #{bearer_token}"
request["Content-Type"] = "application/json"
request.body = {paths: spec_files}.to_json

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
  http.request(request)
end

# write timing data to json file
File.open("timings.json", 'w') do |file|
  file.puts(response.body)
end

# Output the response body
timings = JSON.parse(response.body)

CSV.open("timings.csv", "wb") do |csv|
  timings.to_a.each do |row|
    csv << row
  end
end

File.open("annotation.md", 'w') do |file|
  file.puts("### Timing Data")
  file.puts("|file|time|")
  file.puts("|-|-|")

  timings.each do |key, value|
    file.puts("|[#{key}](https://buildkite.com/organizations/test-analytics-sandbox/analytics/suites/rspec-3/tests?branch=all+branches&period=7days&query=#{key})|#{value}|")
  end
end
