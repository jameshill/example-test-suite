# Define metadata URL
BASE_URL="http://169.254.169.254/latest/meta-data"

# Function to recursively fetch metadata
fetch_metadata() {
  local path=$1
  curl -s "${BASE_URL}/${path}" | while read line; do
    if [[ $line == */ ]]; then
      # It's a directory, call recursively
      sub_path="${path}${line}"
      fetch_metadata "${sub_path}"
    else
      # It's a key-value pair
      value=$(curl -s "${BASE_URL}/${path}${line}")
      echo "\"${line%/}\": \"${value}\","
    fi
  done
}

# Start building JSON
echo "{"
fetch_metadata "" | sed '$ s/,$//'
echo "}"
