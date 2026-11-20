#!/usr/bin/env sh
# Renders every PNG and the favicon from the SVG masters with a pinned VectorCraft, in a container without network.
set -eu

VECTORCRAFT_VERSION=0.24.1
VECTORCRAFT_SHA256=a090514252fde145495ac6fc65d6ff1311d698998e57ba434d5d0896c3d1fbfa
IMAGE=ubuntu:24.04@sha256:73b999393d07f2bf65a40373778a44dc9a6d54ad7718d29247d8ff9413c4d6a8

root=$(cd "$(dirname "$0")/.." && pwd)
cache=${XDG_CACHE_HOME:-$HOME/.cache}/artwork
archive=$cache/vectorcraft-$VECTORCRAFT_VERSION-linux-x86_64.tar.gz
bin=$cache/vectorcraft-$VECTORCRAFT_VERSION

# fetch the pinned release once, then hold every run to its published checksum
if [ ! -f "$archive" ]; then
  mkdir -p "$cache"
  curl -fsSL -o "$archive.part" "https://github.com/storytold/vectorcraft/releases/download/v$VECTORCRAFT_VERSION/vectorcraft-$VECTORCRAFT_VERSION-linux-x86_64.tar.gz"
  mv "$archive.part" "$archive"
fi
echo "$VECTORCRAFT_SHA256  $archive" | sha256sum -c - >/dev/null

# unpack the release beside the archive the first time
if [ ! -d "$bin" ]; then
  mkdir -p "$bin"
  tar -xzf "$archive" -C "$bin" --strip-components=1
fi

# rootful Docker runs the CLI as the calling user, so it writes files that user owns without any capability;
# rootless Docker already maps the container's root to that user
user=
if ! docker info --format '{{.SecurityOptions}}' | grep -q rootless; then
  user="--user $(id -u):$(id -g)"
fi

# run the CLI with the repo as its only writable mount and no network
vc() {
  # shellcheck disable=SC2086 # user is either empty or one flag with its value
  docker run --rm --network none --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges $user \
    -v "$bin:/opt/vc:ro" -v "$root:/w" "$IMAGE" /opt/vc/bin/vectorcraft-cli "$@" >/dev/null
}

# render one master at a pixel width, the scale following from the master's own width
png() {
  width=$(sed -n 's/.*viewBox="0 0 \([0-9.]*\) [0-9.]*".*/\1/p' "$root/$1" | head -n 1)
  vc convert "/w/$1" "/w/$2" --scale "$(awk "BEGIN { printf \"%.6f\", $3 / $width }")"
}

# the logos at the widths a slide, a README and a press page use
for master in logo/full/*.svg logo/mark/*.svg; do
  png "$master" "${master%.svg}.png" 1024
done
for master in logo/lockup/*/*.svg; do
  png "$master" "${master%.svg}.png" 2048
done

# the icons at the sizes browsers and phones ask for
png icons/icon.svg icons/icon-192.png 192
png icons/icon.svg icons/icon-512.png 512
png icons/apple-icon.svg icons/apple-icon.png 180
png icons/og-image.svg icons/og-image.png 1200

# the favicon holds the mark at 16 and 32 pixels
tmp=$(mktemp -d "$root/.favicon.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
rel=${tmp#"$root"/}
png icons/icon.svg "$rel/16.png" 16
png icons/icon.svg "$rel/32.png" 32
python3 "$root/scripts/ico.py" "$root/icons/favicon.ico" "$tmp/16.png" "$tmp/32.png"
