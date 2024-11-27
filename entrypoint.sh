#!/bin/bash

set -e

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "The env variable GITHUB_REPOSITORY is required."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "The env variable GITHUB_EVENT_PATH is required."
  exit 1
fi

GITHUB_TOKEN="$1"

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github+json"
AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"

echo "GITHUB_EVENT_PATH:"
echo "$GITHUB_EVENT_PATH"

echo "GITHUB_REPOSITORY:" 
echo "$GITHUB_REPOSITORY"

echo "GITHUB_TOKEN"
echo "$GITHUB_TOKEN"

number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

autolabel() {
  # Documentation references:
  # https://developer.github.com/v3/pulls/#get-a-single-pull-request

  # Make the API request to get PR information
  body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}")

  # Extract additions and deletions from the response
  additions=$(echo "$body" | jq '.additions')
  deletions=$(echo "$body" | jq '.deletions')

  # Calculate total modifications
  total_modifications=$(echo "$additions + $deletions" | bc)

  # Get the label based on total modifications
  label_to_add=$(label_for "$total_modifications")

  echo "Labeling pull request with $label_to_add"

  curl -sSL \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -H "Content-Type: application/json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -X POST \
    -d "{\"labels\":[\"${label_to_add}\"]}" \
    "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"
}

label_for() {
  if [ "$1" -lt 10 ]; then
    label="size/xs"
  elif [ "$1" -lt 100 ]; then
    label="size/s"
  elif [ "$1" -lt 500 ]; then
    label="size/m"
  elif [ "$1" -lt 1000 ]; then
    label="size/l"
  else
    label="size/xl"
  fi
  
  echo "$label"
}

autolabel