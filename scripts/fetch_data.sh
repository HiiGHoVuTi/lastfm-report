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
PERIOD="31day"
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
echo "Fetching top tracks..."
curl -s "${TRACKS_API_URL}" > "${TRACKS_RAW_RESPONSE_FILE}"

if jq -e '.error' "${TRACKS_RAW_RESPONSE_FILE}" > /dev/null; then
    echo "Error from Last.fm API (top tracks):"
    jq '.' "${TRACKS_RAW_RESPONSE_FILE}"
    exit 1
fi

# Process tracks to add duration, listeners, and tags
echo "Fetching detailed info for each track..."
jq -c '.toptracks.track | map({name, playcount, url, artist: .artist.name}) | .[]' "${TRACKS_RAW_RESPONSE_FILE}" | (
    tracks=()
    while IFS= read -r track_json; do
        track_name=$(echo "$track_json" | jq -r '.name | @uri')
        artist_name=$(echo "$track_json" | jq -r '.artist | @uri')

        # Fetch detailed track info
        TRACK_INFO_URL="http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=${API_KEY}&artist=${artist_name}&track=${track_name}&format=json"
        track_info_json=$(curl -s "$TRACK_INFO_URL")

        # Extract details, using robust checks for older jq versions
        duration=$(echo "$track_info_json" | jq -r 'if .track and .track.duration and (.track.duration|tonumber > 0) then .track.duration | tonumber / 1000 | floor | tostring else "0" end')
        listeners=$(echo "$track_info_json" | jq -r 'if .track and .track.listeners then .track.listeners else "0" end')
        tags=$(echo "$track_info_json" | jq 'if .track and .track.toptags and .track.toptags.tag then .track.toptags.tag | map(.name) else [] end')
        playcount=$(echo "$track_json" | jq -r '.playcount')

        # Calculate total listen time in seconds
        total_listen_seconds=$((playcount * duration))

        # Add new fields to the original track JSON
        updated_track_json=$(echo "$track_json" | jq \
            --argjson duration "$duration" \
            --arg listeners "$listeners" \
            --argjson tags "$tags" \
            --argjson total_listen_seconds "$total_listen_seconds" \
            '. + {duration: $duration, listeners: $listeners, tags: $tags, total_listen_seconds: $total_listen_seconds}')
        
        tracks+=("$updated_track_json")
        echo "Processed: $(echo "$track_json" | jq -r '.artist') - $(echo "$track_json" | jq -r '.name')"
    done

    # Combine all updated track JSON objects into a single array
    printf "%s\n" "${tracks[@]}" | jq -s '.' > public/top-songs.json
)

rm -f "${TRACKS_RAW_RESPONSE_FILE}"
