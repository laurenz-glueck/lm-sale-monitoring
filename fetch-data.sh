#!/bin/bash

# Load environment variables from .env file if exists
[ -f .env ] && source .env

# Array of urls to check
pagesToCrawl=(
  '{ "name": "lm-sale-1", "url": "https://leomathild.com/collections/sample-sale" }'
  '{ "name": "lm-sale-2", "url": "https://leomathild.com/collections/sample-sale?page=2" }'
  '{ "name": "lm-studio-sale-1", "url": "https://lmstudio-jewellery.com/collections/sample-sale" }'
)

# Loop over the array of pages to crawl and fetch the data for each url
for page in "${pagesToCrawl[@]}"; do
  name=$(echo $page | jq -r '.name')
  url=$(echo $page | jq -r '.url')

  # Fetch the url and store the response in a variable
  response=$(curl --location "$url" \
  --header 'Accept-Language: de' \
  --header 'Cache-Control: no-cache' \
  --header 'Connection: keep-alive' \
  --header 'Pragma: no-cache' \
  --header 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 Edg/111.0.1661.62' \
  --fail --silent --show-error)

  # Check if the curl request succeeded or failed
  if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch data for $name"
    exit 1
  else
    echo "Successfully fetched data for $name"
  fi

  # Generate hash from response
  hash=$(echo $response | md5sum | awk '{ print $1 }')

  # Write the hash to a file with the name as the filename
  filePath="./page-history/page-history--$name.txt"

  # Check if the file exists
  if [ -f "$filePath" ]; then
    # Read the hash from the file
    oldHash=$(cat "$filePath")
    # Compare the old hash with the new hash
    if [ "$oldHash" == "$hash" ]; then
      echo "Hashes match. No changes detected."
    else
      echo "Hashes don't match. Changes detected."
      pushResponse=$(curl --location "https://api.pushover.net/1/messages.json" \
        --form-string "token=${PUSHOVER_APP_TOKEN}" \
        --form-string "user=${PUSHOVER_USER_KEY}" \
        --form-string "message=Changes detected for ${name} - ${url}" \
        --fail --silent --show-error)
    fi
  else
    # Create the file
    touch "$filePath"
  fi

  printf $hash > "page-history/page-history--$name.txt"
done
