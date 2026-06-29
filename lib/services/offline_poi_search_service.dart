import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:trufi_core_search_locations/trufi_core_search_locations.dart';

/// A [SearchLocationService] that searches the bundled Sana'a POIs offline.
///
/// The app is offline-first and makes no network calls, so address search is
/// served entirely from the POI GeoJSON assets shipped with the app (the same
/// data the map's POI layers use). Matching is a case-insensitive substring
/// over each place's Arabic and English names plus its street.
class OfflinePoiSearchService implements SearchLocationService {
  OfflinePoiSearchService({
    required this.poiAssetPaths,
    this.biasLatitude,
    this.biasLongitude,
    this.maxResults = 25,
  });

  /// GeoJSON asset paths to index (FeatureCollections of Point features).
  final List<String> poiAssetPaths;

  /// Optional bias point: on equal relevance, nearer results rank first.
  final double? biasLatitude;
  final double? biasLongitude;

  /// Maximum number of results returned by [search].
  final int maxResults;

  List<_PoiEntry>? _entries;

  Future<List<_PoiEntry>> _loadEntries() async {
    final cached = _entries;
    if (cached != null) return cached;

    final entries = <_PoiEntry>[];
    for (final path in poiAssetPaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final features = decoded['features'] as List<dynamic>? ?? const [];
        for (final f in features) {
          final feature = f as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          if (coords == null || coords.length < 2) continue;
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();

          final props =
              (feature['properties'] as Map<String, dynamic>?) ?? const {};
          final name = _firstNonEmpty([
            props['name'],
            props['name:ar'],
            props['name:en'],
          ]);
          if (name == null) continue; // unnamed POIs aren't searchable

          final id = '${props['id'] ?? feature['id'] ?? '$lat,$lon'}';
          final address = _firstNonEmpty([
            props['addr:street'],
            props['addr:city'],
            props['subcategory'],
            props['category'],
          ]);
          final haystack = [
            props['name'],
            props['name:ar'],
            props['name:en'],
            props['addr:street'],
          ].whereType<String>().join(' ').toLowerCase();

          entries.add(
            _PoiEntry(
              id: id,
              name: name,
              address: address,
              latitude: lat,
              longitude: lon,
              haystack: haystack,
            ),
          );
        }
      } catch (_) {
        // A single malformed/missing POI file shouldn't break search.
        continue;
      }
    }

    _entries = entries;
    return entries;
  }

  @override
  Future<List<SearchLocation>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final entries = await _loadEntries();
    final matches = <_PoiEntry>[
      for (final e in entries)
        if (e.haystack.contains(q)) e,
    ];

    int rank(_PoiEntry e) => e.name.toLowerCase().startsWith(q) ? 0 : 1;
    matches.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      if (biasLatitude != null && biasLongitude != null) {
        return _distanceSq(a).compareTo(_distanceSq(b));
      }
      return a.name.compareTo(b.name);
    });

    return [
      for (final e in matches.take(maxResults)) e.toSearchLocation(),
    ];
  }

  @override
  Future<SearchLocation?> reverse(double latitude, double longitude) async {
    final entries = await _loadEntries();
    if (entries.isEmpty) return null;

    _PoiEntry? nearest;
    var nearestSq = double.infinity;
    for (final e in entries) {
      final dLat = e.latitude - latitude;
      final dLon = e.longitude - longitude;
      final d = dLat * dLat + dLon * dLon;
      if (d < nearestSq) {
        nearestSq = d;
        nearest = e;
      }
    }

    // ~0.0015° ≈ 150 m: only snap to a POI that's genuinely close, otherwise
    // let the caller fall back to a generic "dropped pin" label.
    if (nearest == null || nearestSq > 0.0015 * 0.0015) return null;
    return nearest.toSearchLocation();
  }

  @override
  void dispose() {
    _entries = null;
  }

  double _distanceSq(_PoiEntry e) {
    final dLat = e.latitude - biasLatitude!;
    final dLon = e.longitude - biasLongitude!;
    return dLat * dLat + dLon * dLon;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}

class _PoiEntry {
  const _PoiEntry({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.haystack,
  });

  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String haystack;

  SearchLocation toSearchLocation() => SearchLocation(
    id: id,
    displayName: name,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}
