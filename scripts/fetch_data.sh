#!/bin/bash

set -e

if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it."
    exit
fi

# Source environment variables if .env file exists
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

API_KEY=${API_KEY}
USERNAME="jupons"
PERIOD="7day"
LIMIT="10"

# Fetch top artists
ARTISTS_API_URL="http://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=${USERNAME}&api_key=${API_KEY}&period=${PERIOD}&limit=${LIMIT}&format=json"
ARTISTS_RAW_RESPONSE_FILE="public/artists_response.json"
curl -s "${ARTISTS_API_URL}" > "${ARTISTS_RAW_RESPONSE_FILE}"

if jq -e '.error' "${ARTISTS_RAW_RESPONSE_FILE}" > /dev/null; then
    echo "Error from Last.fm API (artists):"
    jq '.' "${ARTISTS_RAW_RESPONSE_FILE}"
    exit 1
fi

jq '.topartists.artist | map({name, playcount, url})' "${ARTISTS_RAW_RESPONSE_FILE}" > public/data.json
rm -f "${ARTISTS_RAW_RESPONSE_FILE}"

# Fetch top songs
TRACKS_API_URL="http://ws.audioscrobbler.com/2.0/?method=user.gettoptracks&user=${USERNAME}&api_key=${API_KEY}&period=${PERIOD}&limit=${LIMIT}&format=json"
TRACKS_RAW_RESPONSE_FILE="public/tracks_response.json"
curl -s "${TRACKS_API_URL}" > "${TRACKS_RAW_RESPONSE_FILE}"

if jq -e '.error' "${TRACKS_RAW_RESPONSE_FILE}" > /dev/null; then
    echo "Error from Last.fm API (tracks):"
    jq '.' "${TRACKS_RAW_RESPONSE_FILE}"
    exit 1
fi

jq '.toptracks.track | map({name, playcount, url})' "${TRACKS_RAW_RESPONSE_FILE}" > public/top-songs.json
rm -f "${TRACKS_RAW_RESPONSE_FILE}"
