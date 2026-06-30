# pbf-yemen-sanaa

Generates a Sana'a `.osm.pbf` extract using [`trufi-association/trufi-pbf-extractor`](https://github.com/trufi-association/trufi-pbf-extractor). The extractor's image is built on the fly from the upstream repo, pinned to a commit in [`docker-compose.yml`](docker-compose.yml) — no fork, no submodule.

## Run

```bash
docker compose up --build
```

Output: `./out/sanaa.osm.pbf` (committed to the repo; everything else under `out/` is gitignored). Most of the time is the ~40 MB Yemen download from Geofabrik.

## What it does

```bash
wget https://download.geofabrik.de/asia/yemen-latest.osm.pbf
osmium extract --bbox="$BBOX" --set-bounds yemen-latest.osm.pbf --output sanaa.osm.pbf
```

Values come from [`.env`](.env).

## Bounding box

The bbox in `.env` covers Sana'a and its immediate surroundings:

```
west=44.023938, south=15.161991, east=44.399674, north=15.642149
```

It is shared by the GTFS builder (`../gtfs-yemen-sanaa`) and the tile generator (`../mbtiles-yemen-sanaa`), which both read this PBF.

## Pin

`docker-compose.yml` pins the upstream image to commit `b9e04c32ced29f0925d956dd12ad3271a4bce392`. The repo has no tags; bump the SHA when you want a newer build. Buildkit requires the full 40-character SHA.

## Inspect the PBF

```bash
docker run --rm -v "$PWD/out:/d" stefda/osmium-tool fileinfo /d/sanaa.osm.pbf
```
