#!/usr/bin/env bash
#
# Regenerate assets/offline/sanaa.mbtiles from OpenStreetMap.
#
# This produces the offline vector tiles bundled with the app. They follow the
# OpenMapTiles schema, so they render with the bundled MapLibre styles in
# assets/offline/styles/ (osm-liberty, osm-bright, dark-matter, fiord-color) —
# exactly the same pipeline the upstream Trufi Cochabamba app uses.
#
# Run this whenever you want to refresh the map (e.g. after OpenStreetMap
# coverage for Sana'a improves). Requires Docker.
#
# NOTE on density: the tiles only contain what OpenStreetMap has for the area.
# As of this writing OSM coverage for Sana'a / Yemen is sparse compared to
# well-mapped cities (few building footprints, fewer minor streets). The map
# renders all available data; to make it denser, the data has to be added to
# OpenStreetMap upstream, then re-run this script.
#
# Usage:
#   ./tools/mbtiles/regenerate-sanaa-mbtiles.sh
#
set -euo pipefail

# --- config ---------------------------------------------------------------
# Bounding box for the Sana'a build (minLon,minLat,maxLon,maxLat).
BOUNDS="44.023938,15.161991,44.399674,15.642149"
MIN_ZOOM=0
MAX_ZOOM=14
# Geofabrik extract that contains Sana'a.
OSM_URL="https://download.geofabrik.de/asia/yemen-latest.osm.pbf"
PLANETILER_IMAGE="openmaptiles/planetiler-openmaptiles:3.16"

# --- paths ----------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK_DIR="${WORK_DIR:-/tmp/sanaa-tiles}"
ASSET_PATH="$REPO_ROOT/assets/offline/sanaa.mbtiles"

mkdir -p "$WORK_DIR/in" "$WORK_DIR/out"

# --- 1. download the OSM extract -----------------------------------------
PBF="$WORK_DIR/in/yemen.osm.pbf"
if [[ ! -s "$PBF" ]]; then
  echo "==> Downloading Yemen OSM extract..."
  # --retry guards against the truncated-download failure that produces a
  # silently incomplete .pbf (planetiler then fails with a partial-read error).
  curl -sSL --retry 4 --retry-delay 2 -o "$PBF" "$OSM_URL"
fi
echo "==> OSM extract: $(du -h "$PBF" | cut -f1) ($PBF)"

# --- 2. run planetiler ----------------------------------------------------
# --storage=ram + --osm_lazy_reads=false avoid the mmap "cannot extend file"
# failure seen on Docker Desktop for Mac (gRPC-FUSE / virtiofs backed volumes).
echo "==> Generating tiles with planetiler (bounds=$BOUNDS, z$MIN_ZOOM-$MAX_ZOOM)..."
docker run --rm \
  -v "$WORK_DIR:/data" \
  "$PLANETILER_IMAGE" \
  --osm-path=/data/in/yemen.osm.pbf \
  --output=/data/out/sanaa.mbtiles \
  --bounds="$BOUNDS" \
  --minzoom="$MIN_ZOOM" \
  --maxzoom="$MAX_ZOOM" \
  --storage=ram \
  --osm_lazy_reads=false \
  --force

# --- 3. install into the app ---------------------------------------------
cp "$WORK_DIR/out/sanaa.mbtiles" "$ASSET_PATH"
echo "==> Installed $(du -h "$ASSET_PATH" | cut -f1) -> $ASSET_PATH"
echo "==> Done. Rebuild the app to pick up the new tiles."
