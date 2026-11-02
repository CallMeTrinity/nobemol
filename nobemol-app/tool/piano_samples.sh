#!/usr/bin/env bash
# Prépare les notes de piano de l'appli (assets/audio/piano/), à lancer une
# fois : les fichiers produits sont commités, la CI n'en a pas besoin.
#
# Source : Salamander Grand Piano V3, Alexander Holm, CC-BY 3.0
# (https://github.com/sfzinstruments/SalamanderGrandPiano). Un Yamaha C5
# échantillonné toutes les tierces mineures, du la0 au do8 : 30 notes.
#
# Pour chaque note, la vélocité 10 sur 16 (mezzo forte), puis :
# mono, début calé sur l'attaque, 2,5 s avec extinction sur la dernière
# seconde, 32 kHz, Ogg Vorbis. Le même gain pour toutes : l'équilibre
# naturel entre graves et aigus reste celui du piano.
#
# Nommés par numéro MIDI (21 = la0, 60 = do4, 108 = do8).
#
# Prérequis : sox avec Vorbis et FLAC (brew install sox), curl.
# Usage : tool/piano_samples.sh [dossier de cache]
# Le cache garde les FLAC originaux (45 Mo), hors du repo.

set -euo pipefail
export LC_ALL=C

cd "$(dirname "$0")/.."
cache="${1:-${TMPDIR:-/tmp}/salamander}"
out=assets/audio/piano
base=https://raw.githubusercontent.com/sfzinstruments/SalamanderGrandPiano/master/Samples
velocity=10
names=(C D# F# A)
length=2.5
fade=1.0

mkdir -p "$cache" "$out"

# Numéro MIDI et nom Salamander (« D#4 ») de chaque note échantillonnée.
notes=()
for midi in $(seq 21 3 108); do
  octave=$((midi / 12 - 1))
  notes+=("$midi:${names[$(((midi % 12) / 3))]}$octave")
done

# Mono, attaque au début (on coupe ce qui précède -40 dB), 2,5 s.
shape() {
  sox "$1" -t sox - channels 1 silence 1 0.001 1% trim 0 "$length"
}

for note in "${notes[@]}"; do
  name=${note#*:}
  file="$cache/${name}v$velocity.flac"
  if [[ ! -s "$file" ]]; then
    echo "Téléchargement de $name"
    curl -sfL -o "$file" "$base/${name//#/%23}v$velocity.flac"
  fi
done

# Le pic le plus fort de toutes les notes, ramené à -1 dB.
peak=0
for note in "${notes[@]}"; do
  name=${note#*:}
  level=$(shape "$cache/${name}v$velocity.flac" | sox -t sox - -n stat 2>&1 |
    awk '/Maximum amplitude/ { print $3 }')
  peak=$(awk -v a="$peak" -v b="$level" 'BEGIN { print (b > a ? b : a) }')
done
gain=$(awk -v p="$peak" 'BEGIN { printf "%.2f", 20 * log(0.89 / p) / log(10) }')
echo "Pic $peak, gain $gain dB"

rm -f "$out"/*.ogg
for note in "${notes[@]}"; do
  midi=${note%%:*}
  name=${note#*:}
  shape "$cache/${name}v$velocity.flac" |
    sox -t sox - -r 32000 -C 3 "$out/$midi.ogg" \
      gain "$gain" fade q 0.002 "$length" "$fade"
done

du -sh "$out"
