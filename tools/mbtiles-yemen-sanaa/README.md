# mbtiles-yemen-sanaa

Generates the Sana'a `.mbtiles` (vector tiles for the offline map) using `openmaptiles/planetiler-openmaptiles`. Compose mirrors [`trufi-association/trufi-mbtiles-generator`](https://github.com/trufi-association/trufi-mbtiles-generator) with the input mount adjusted to read the sibling tool's PBF.

The tiles follow the OpenMapTiles schema, so they render with the bundled MapLibre style in [`assets/offline/styles/osm-liberty/`](../../assets/offline/styles/osm-liberty/) — the same pipeline the upstream Trufi (Cochabamba) app uses.

## Run

```bash
docker compose up
```

Output: `./out/sanaa.mbtiles` (committed). First run downloads Natural Earth + water polygon sources (~200 MB) which planetiler caches in the container. Copy the result into the app:

```bash
cp out/sanaa.mbtiles ../../assets/offline/sanaa.mbtiles
```

## Input

Reads `../pbf-yemen-sanaa/out/sanaa.osm.pbf` (mounted read-only). Generate it first with the sibling tool.

## Sana'a tweaks

City-specific values live in [`.env`](.env): `CITY_NAME`, `MAX_ZOOM` (14, matching the bundled tiles), `MIN_ZOOM`, `JAVA_MEMORY`, `THREADS`.

## A note on map density

The tiles contain only what OpenStreetMap has for the area. OSM coverage for
Sana'a / Yemen is sparser than well-mapped cities (the main road network is
present, but fewer building footprints and minor streets). The map renders all
available data; to densify it, contribute to OpenStreetMap upstream and re-run.

## Pin

The image tag is `openmaptiles/planetiler-openmaptiles:3.16` — the latest stable (non-SNAPSHOT) tag. Bump it when a newer stable tag ships.
