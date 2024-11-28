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

xs_max_size="$2"
s_max_size="$3"
m_max_size="$4"
l_max_size="$5"

fail_if_xl="$6"

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

  if [ "$label_to_add" = "size/xl" ] && [ "$fail_if_xl" = "true" ]; then
    echo "Pr is xl, please, short this!!"
    exit 1
  fi
}

label_for() {
  if [ "$1" -lt "$xs_max_size" ]; then
    label="size/xs"
  elif [ "$1" -lt "$s_max_size" ]; then
    label="size/s"
  elif [ "$1" -lt "$m_max_size" ]; then
    label="size/m"
  elif [ "$1" -lt "$l_max_size" ]; then
    label="size/l"
  else
    label="size/xl"
  fi
  
  echo "$label"
}

autolabel

exit $?