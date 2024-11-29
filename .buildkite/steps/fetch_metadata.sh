#!/bin/bash

# Define metadata URL
BASE_URL="http://169.254.169.254/latest/meta-data"

# Function to recursively fetch metadata and build JSON
fetch_metadata() {
  local path=$1
  local output=""

  # Fetch metadata at this path
  local data=$(curl -s "${BASE_URL}/${path}")

  while read -r line; do
    # Check if this is a directory
    if [[ $line == */ ]]; then
      # Recursively fetch nested metadata
      local sub_key="${line%/}" # Remove trailing slash
      local sub_path="${path}${sub_key}/"
      local sub_output=$(fetch_metadata "${sub_path}")
      output="${output}\"${sub_key}\": ${sub_output},"
    else
      # It's a key-value pair
      local value=$(curl -s "${BASE_URL}/${path}${line}" | sed -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g')
      output="${output}\"${line}\": \"${value}\","
    fi
  done <<<"$data"

  # Wrap output in braces for objects
  if [[ $output ]]; then
    echo "{${output%,}}" # Remove trailing comma and wrap in braces
  else
    echo "\"$data\"" # For scalar values, return as string
  fi
}

# Start building JSON from the root path and escape control characters
fetch_metadata "" | sed -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g' | jq .
