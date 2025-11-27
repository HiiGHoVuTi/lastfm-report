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

cat > "$OUTPUT_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Last.fm Recap</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>My Last.fm Recap</h1>
        <div id="songs">
            <h2>Top Songs</h2>
            <ul>
EOF

jq -r '.[] | "<li><a href=\"" + .url + "\">" + .name + "</a> (" + .playcount + " plays)</li>"' "$SONGS_DATA_FILE" >> "$OUTPUT_FILE"

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
