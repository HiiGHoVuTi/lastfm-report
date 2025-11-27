#!/bin/bash

set -e

ARTISTS_DATA_FILE="public/data.json"
SONGS_DATA_FILE="public/top-songs.json"
OUTPUT_FILE="public/index.html"

if [ ! -f "$ARTISTS_DATA_FILE" ]; then
    echo "Artists data file not found: $ARTISTS_DATA_FILE"
    exit 1
fi

if [ ! -f "$SONGS_DATA_FILE" ]; then
    echo "Songs data file not found: $SONGS_DATA_FILE"
    exit 1
fi

REPUBLICAN_DATE=$(bash scripts/republican_date.sh)

# Helper function to format seconds into a human-readable string
format_seconds() {
    local total_seconds=$1
    if [ -z "$total_seconds" ] || [ "$total_seconds" -eq 0 ]; then
        echo ""
        return
    fi
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    echo "${hours}h ${minutes}m"
}

# Calculate total listening time
overall_total_seconds=$(jq '[.[] | .total_listen_seconds] | add' "$SONGS_DATA_FILE")
formatted_overall_time=$(format_seconds "$overall_total_seconds")

        # <p>Total listening time for top songs: <strong>${formatted_overall_time}</strong></p>
cat > "$OUTPUT_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Last.fm Recap</title>
    <link rel="stylesheet" href="style.css">
    <style>
        .subtitle {
            font-size: 0.85em;
            color: #777;
            margin-left: 2px;
        }
        li {
            margin-bottom: 12px;
        }
        strong {
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>My Last.fm Recap</h1>
        <div id="songs">
            <h2>Top Songs</h2>
            <ul>
EOF

# Generate song list with detailed info
jq -c '.[]' "$SONGS_DATA_FILE" | while IFS= read -r song_json; do
    name=$(echo "$song_json" | jq -r '.name')
    artist=$(echo "$song_json" | jq -r '.artist')
    url=$(echo "$song_json" | jq -r '.url')
    playcount=$(echo "$song_json" | jq -r '.playcount')
    
    total_listen_seconds=$(echo "$song_json" | jq -r '.total_listen_seconds')
    formatted_time=$(format_seconds "$total_listen_seconds")
    
    listeners=$(echo "$song_json" | jq -r '.listeners')
    # Format listeners with commas for readability
    formatted_listeners=$(echo "$listeners" | sed -E ':a;s/([0-9])([0-9]{3})($|[^0-9])/\1,\2\3/;ta')

    tags=$(echo "$song_json" | jq -r '.tags | .[0:2] | join(", ")')

    echo "            <li>" >> "$OUTPUT_FILE"
    echo "                <a href=\"$url\">$artist - $name</a> ($playcount plays)" >> "$OUTPUT_FILE"
    if [ -n "$formatted_time" ]; then
        echo " - <strong>$formatted_time</strong>" >> "$OUTPUT_FILE"
    fi
    
    subtitle_parts=()
    if [ "$listeners" != "0" ]; then
        subtitle_parts+=("Listeners: $formatted_listeners")
    fi
    if [ -n "$tags" ]; then
        subtitle_parts+=("Tags: $tags")
    fi
    
    if [ ${#subtitle_parts[@]} -gt 0 ]; then
        subtitle_string=$(IFS=" | "; echo "${subtitle_parts[*]}")
        echo "                <div class=\"subtitle\">$subtitle_string</div>" >> "$OUTPUT_FILE"
    fi
    
    echo "            </li>" >> "$OUTPUT_FILE"
done

cat >> "$OUTPUT_FILE" <<EOF
            </ul>
        </div>
        <div id="artists">
            <h2>Top Artists</h2>
            <ul>
EOF

jq -r '.[] | "<li><a href=\"" + .url + "\">" + .name + "</a> (" + .playcount + " plays)</li>"' "$ARTISTS_DATA_FILE" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" <<EOF
            </ul>
        </div>
        <footer>
            <p>Last updated: ${REPUBLICAN_DATE}</p>
        </footer>
    </div>
</body>
</html>
EOF
echo "HTML file generated: $OUTPUT_FILE"
