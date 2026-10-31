#!/bin/sh
# Génère les icônes PNG de l'appli depuis nobemol-icone.svg (racine du repo) :
# Android 7 (mipmap-*/ic_launcher.png), web (icons/, favicon.png).
#
# Depuis nobemol-app : sh tool/icons.sh
#
# macOS : Chrome dessine le SVG (fond transparent), sips le réduit. L'icône
# adaptative d'Android 8 et plus est vectorielle, écrite à la main
# (res/drawable/ic_launcher_foreground.xml) : à reprendre si le SVG change.
set -eu

app=$(cd "$(dirname "$0")/.." && pwd)
svg="$app/../nobemol-icone.svg"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Dessine $1 (un SVG) en carré de 1024 px dans $2.
render() {
  cp "$1" "$work/icon.svg"
  printf '<html><body style="margin:0"><img src="icon.svg" width="1024" height="1024"></body></html>' \
    > "$work/icon.html"
  "$chrome" --headless --disable-gpu --hide-scrollbars \
    --default-background-color=00000000 --window-size=1024,1024 \
    --screenshot="$2" "file://$work/icon.html" 2>/dev/null
}

# Réduit $1 à $2 px de côté dans $3.
resize() {
  mkdir -p "$(dirname "$3")"
  sips -z "$2" "$2" "$1" --out "$3" > /dev/null
}

render "$svg" "$work/rounded.png"
# Web « maskable » : le navigateur découpe lui-même, le fond va jusqu'au bord.
sed 's/rx="[0-9]*"/rx="0"/' "$svg" > "$work/square.svg"
render "$work/square.svg" "$work/square.png"

res="$app/android/app/src/main/res"
resize "$work/rounded.png" 48 "$res/mipmap-mdpi/ic_launcher.png"
resize "$work/rounded.png" 72 "$res/mipmap-hdpi/ic_launcher.png"
resize "$work/rounded.png" 96 "$res/mipmap-xhdpi/ic_launcher.png"
resize "$work/rounded.png" 144 "$res/mipmap-xxhdpi/ic_launcher.png"
resize "$work/rounded.png" 192 "$res/mipmap-xxxhdpi/ic_launcher.png"

resize "$work/rounded.png" 192 "$app/web/icons/Icon-192.png"
resize "$work/rounded.png" 512 "$app/web/icons/Icon-512.png"
resize "$work/square.png" 192 "$app/web/icons/Icon-maskable-192.png"
resize "$work/square.png" 512 "$app/web/icons/Icon-maskable-512.png"
resize "$work/rounded.png" 32 "$app/web/favicon.png"

echo "Icônes générées depuis $(basename "$svg")."
