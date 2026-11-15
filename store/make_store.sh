#!/usr/bin/env bash
# Builds the Play Store graphics from store/raw/ (screenshots taken on an Oppo Reno14 F,
# release build) and assets/icon/icon.svg. Needs ImageMagick and Inkscape.
set -euo pipefail
cd "$(dirname "$0")"
FONT=DejaVu-Sans-Bold

inkscape ../assets/icon/icon.svg --export-type=png --export-width=512 --export-filename=play-icon-512.png >/dev/null 2>&1

# Phone screenshots: 2400x1200 JPEG (Play allows at most 2:1 and 8 MB), caption on top.
caption() { # raw out text
  convert -size 2400x1200 gradient:'#3A1A80-#14082E' \
    \( "$1" -resize 2200x -bordercolor '#FFFFFF33' -border 4 \) -gravity south -geometry +0+40 -composite \
    -font "$FONT" -pointsize 84 -fill white -gravity north -annotate +0+50 "$3" -alpha off -quality 88 "$2"
}
caption raw/1-piano.png screenshots/01-piano.jpg  "Big rainbow keys and party lights"
caption raw/2-drums.png screenshots/02-drums.jpg  "Bang the happy drum kit"
caption raw/3-silly.png screenshots/03-silly.jpg  "Boing, quack, zap: silly sounds!"
caption raw/4-songs.png screenshots/04-songs.jpg  "Magic songs: any key plays the tune"
caption raw/5-find.png  screenshots/05-find.jpg   "Find the shining key, win stars"

# Feature graphic 1024x500: title left, the keyboard on the right.
convert -size 1024x500 gradient:'#3A1A80-#14082E' \
  \( raw/1-piano.png -crop 2240x700+110+385 +repage -resize 560x \) -gravity east -geometry +28+0 -composite \
  -gravity northwest -font "$FONT" -fill white -pointsize 64 -annotate +40+140 "Rainbow" -annotate +40+215 "Keys" \
  -fill '#FFE45C' -pointsize 34 -annotate +42+300 "Toddler Piano" \
  -fill '#D8CCFF' -pointsize 22 -annotate +42+352 "Party lights · happy sounds" -annotate +42+382 "No login · made for little hands" \
  -alpha off feature-graphic-1024x500.png
echo done
