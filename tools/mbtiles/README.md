# Offline map tiles (`sanaa.mbtiles`)

The app ships fully offline. The base map is a vector-tile MBTiles file at
[`assets/offline/sanaa.mbtiles`](../../assets/offline/sanaa.mbtiles), rendered
locally by MapLibre with the styles in
[`assets/offline/styles/`](../../assets/offline/styles/).

The tiles use the **OpenMapTiles** schema and are generated with
[planetiler](https://github.com/onthegomap/planetiler) from an OpenStreetMap
extract — the same pipeline the upstream Trufi (Cochabamba) app uses.

## Regenerate

```bash
./tools/mbtiles/regenerate-sanaa-mbtiles.sh
```

Requires Docker. It downloads the Yemen OSM extract from Geofabrik, runs
planetiler for the Sana'a bounding box (`44.023938,15.161991,44.399674,15.642149`,
zoom 0–14), and copies the result over `assets/offline/sanaa.mbtiles`. Then
rebuild the app.

## A note on map density

The tiles contain **only what OpenStreetMap has** for the area. OSM coverage for
Sana'a / Yemen is currently sparse compared to well-mapped cities: the main road
network is present, but there are few building footprints and fewer minor
streets than you'd see in, say, Cochabamba. This is a data-availability reality,
not an app bug — the map renders everything that exists in the source data.

To make the map denser, the missing geometry has to be contributed to
OpenStreetMap upstream; re-running the script then picks it up.
