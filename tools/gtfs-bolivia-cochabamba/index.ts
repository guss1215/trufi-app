/**
 * Cochabamba GTFS generator.
 *
 * Uses trufi-gtfs-builder as a library. Output goes to ./out/.
 * The resulting gtfs.zip is what gets shipped to:
 *   - trufi-app/assets/routing/cochabamba.gtfs.zip (offline routing in the APK)
 *   - trufi-server-otp/cochabamba.gtfs.zip (OTP servers)
 *
 * Starting point: upstream example at
 * https://github.com/trufi-association/trufi-gtfs-builder/tree/v2.13.0/examples/Bolivia-Cochabamba
 *
 * Cochabamba-specific tweaks live below — adjust them here, not in upstream.
 */

import { osmToGtfs, OSMOverpassDownloader, OSMPBFReader } from 'trufi-gtfs-builder';
import * as path from 'path';
import * as fs from 'fs';

type DataSource = 'overpass' | 'pbf';

const DATA_SOURCE: DataSource = 'pbf';

const PBF_FILE = path.join(__dirname, '..', 'pbf-bolivia-cochabamba', 'out', 'cochabamba.osm.pbf');

const BOUNDING_BOX = {
  south: -17.709721,
  west: -66.440262,
  north: -17.261759,
  east: -65.577835,
};

function getOsmDataGetter() {
  if (DATA_SOURCE === 'pbf') {
    if (!fs.existsSync(PBF_FILE)) {
      throw new Error(
        `PBF file not found: ${PBF_FILE}\n` +
        `Generate it with the sibling tool: cd ../pbf-bolivia-cochabamba && docker compose up --build`,
      );
    }
    return new OSMPBFReader(PBF_FILE);
  }
  return new OSMOverpassDownloader(BOUNDING_BOX);
}

async function main() {
  console.log(`Generating GTFS for Cochabamba (source: ${DATA_SOURCE})...`);

  await osmToGtfs({
    outputFiles: {
      outputDir: path.join(__dirname, 'out'),
      gtfs: true,
      gtfsZip: true,
      readme: true,
      log: true,
      stops: true,
      routes: false,
      trufiTPData: false,
    },
    geojsonOptions: {
      osmDataGetter: getOsmDataGetter(),
      transformTypes: ['bus', 'share_taxi', 'minibus', 'aerialway', 'light_rail'],
      // Routes excluded from the feed (problematic OSM relations).
      skipRoute: (route) =>
        ![2084702, 16533147, 17193322, 16648003, 17193322].includes(route.id),
    },
    gtfsOptions: {
      agencyTimezone: 'America/La_Paz',
      agencyUrl: 'https://www.cochabamba.bo/',
      cityName: 'cochabamba',
      defaultCalendar: () => 'Mo-Su 06:00-22:00',
      frequencyHeadway: () => 300,
      vehicleSpeed: () => 40,
      // Most Cochabamba minibus lines have no physical stops mapped in
      // OSM, so they get `fakeStops` (a stop per shape node, then
      // segment-merge + gap-fill at `fakeStopsGapThreshold` density).
      // The few routes listed below DO have stops mapped in OSM and use
      // them directly.
      stopsConfig: (route: any) => {
        const ROUTES_WITH_OSM_STOPS = [
          11678428,
          19604339,
          9083839,
          14576927,
          9074378,
          14576926,
          6925236,
          6925237,
        ];
        if (ROUTES_WITH_OSM_STOPS.includes(route.properties.id)) {
          return { mode: 'osmStops', forceEndpointStops: true };
        }
        return { mode: 'fakeStops' };
      },
      fakeStopsGapThreshold: 100,
      stopNameBuilder: (stops: string[] | undefined) => {
        if (!stops || stops.length === 0) {
          stops = ['Innominada'];
        }
        return stops.join(' y ');
      },
      feed: {
        publisherName: 'Trufi Association',
        publisherUrl: 'https://www.trufi-association.org/',
        lang: 'es',
        version: '1.0',
        contactEmail: 'info@trufi-association.org',
        contactUrl: 'https://www.trufi-association.org/',
        startDate: '20240101',
        endDate: '20261231',
        id: 'cochabamba',
      },
    },
  });

  console.log(`Done. Output in ${path.join(__dirname, 'out')}`);
}

main().catch((err) => {
  console.error('GTFS generation failed:', err);
  process.exit(1);
});
