import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'progress_store.dart';

class RoutingException implements Exception {
  RoutingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RouteStep {
  RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.endIndex,
  });

  /// Localized human-readable instruction, e.g. "Rechts abbiegen auf Hauptstraße".
  final String instruction;

  /// Length of this step in meters.
  final double distanceMeters;

  /// Index in the route polyline where this step ends (i.e. where the
  /// next maneuver happens). Use this to look up the trigger coordinate.
  final int endIndex;
}

class RouteResult {
  RouteResult({
    required this.points,
    required this.elevations,
    required this.distanceMeters,
    required this.ascentMeters,
    required this.descentMeters,
    required this.steps,
  });

  final List<LatLng> points;
  final List<double> elevations;
  final double distanceMeters;
  final double ascentMeters;
  final double descentMeters;
  final List<RouteStep> steps;

  double get distanceKm => distanceMeters / 1000.0;
}

/// Thin wrapper around the OpenRouteService Directions API for walking routes.
///
/// Why OpenRouteService:
/// - Free tier: 2,000 requests / day, no credit card required.
/// - The `foot-walking` profile only routes on walkable infrastructure
///   (no motorways/autobahns), exactly like Google Maps "walking" mode.
/// - A single request returns the polyline, total distance and elevation
///   gain/loss when `elevation: true` is set.
///
/// To use:
/// 1. Create a free account at https://openrouteservice.org/dev/#/signup
/// 2. Generate an API token.
/// 3. Add ORS_API_KEY to the ignored config/local.defines.json and run/build
///    with --dart-define-from-file=config/local.defines.json.
class RoutingService {
  RoutingService._();

  static const String _envApiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue: '',
  );

  static String get apiKey => _envApiKey.trim();

  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Calculates a walking route through [waypoints] in order.
  /// First entry is the start, last is the destination, anything in between
  /// is treated as a forced via-point.
  static Future<RouteResult> getWalkingRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      throw RoutingException('Mindestens Start und Ziel sind erforderlich.');
    }
    final key = apiKey;
    if (key.isEmpty) {
      throw RoutingException(
        'Kein OpenRouteService API-Key konfiguriert.\n'
        'Konfiguriere ORS_API_KEY über --dart-define-from-file.',
      );
    }

    final uri = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/foot-walking/geojson',
    );
    final body = jsonEncode({
      'coordinates': waypoints
          .map((c) => [c.longitude, c.latitude])
          .toList(growable: false),
      'elevation': true,
      'instructions': true,
      'language': ProgressStore.appLocaleCode,
      'units': 'm',
    });

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Authorization': key,
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json, application/geo+json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw RoutingException(
        'Konnte den Routing-Server nicht erreichen.\nPrüfe deine Internetverbindung.\n($e)',
      );
    }

    if (response.statusCode != 200) {
      throw RoutingException(
        'Routing-Anfrage fehlgeschlagen (HTTP ${response.statusCode}). '
        '${_extractError(response.body)}',
      );
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final features = (data['features'] as List?) ?? const [];
    if (features.isEmpty) {
      throw RoutingException(
        'Keine gehbare Route gefunden. '
        'Setze deine Punkte näher an einen Weg oder eine Straße.',
      );
    }
    final feature = features.first as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = (geometry['coordinates'] as List).cast<List>();

    final points = <LatLng>[];
    final elevations = <double>[];
    for (final c in coords) {
      // ORS GeoJSON coordinates: [lon, lat, ele]
      final lon = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      final ele = c.length >= 3 ? (c[2] as num).toDouble() : 0.0;
      points.add(LatLng(lat, lon));
      elevations.add(ele);
    }

    final props = (feature['properties'] as Map<String, dynamic>?) ?? const {};
    final summary = (props['summary'] as Map<String, dynamic>?) ?? const {};
    final distance = (summary['distance'] as num?)?.toDouble() ?? 0.0;
    var ascent = (summary['ascent'] as num?)?.toDouble() ?? 0.0;
    var descent = (summary['descent'] as num?)?.toDouble() ?? 0.0;

    // ORS regularly returns ascent/descent == 0 for short routes because the
    // SRTM digital-elevation grid (~30 m) collapses several polyline points
    // onto the same pixel. The 3D coordinates themselves still carry usable
    // height data, so when the server-side summary is empty but we have
    // per-point elevations, compute ascent/descent locally.
    if ((ascent <= 0 && descent <= 0) && elevations.length >= 2) {
      final computed = _ascentDescentFromElevations(elevations);
      ascent = computed.ascent;
      descent = computed.descent;
    }

    final steps = <RouteStep>[];
    final segments = (props['segments'] as List?) ?? const [];
    for (final seg in segments) {
      if (seg is! Map) continue;
      final segSteps = (seg['steps'] as List?) ?? const [];
      for (final s in segSteps) {
        if (s is! Map) continue;
        final instruction = (s['instruction'] ?? '').toString().trim();
        if (instruction.isEmpty) continue;
        final dist = (s['distance'] as num?)?.toDouble() ?? 0.0;
        // way_points: [startIdx, endIdx] into the polyline.
        final wp = (s['way_points'] as List?) ?? const [];
        final endIdx = wp.length >= 2
            ? (wp[1] as num).toInt()
            : (points.isEmpty ? 0 : points.length - 1);
        steps.add(
          RouteStep(
            instruction: instruction,
            distanceMeters: dist,
            endIndex: endIdx.clamp(0, points.isEmpty ? 0 : points.length - 1),
          ),
        );
      }
    }

    return RouteResult(
      points: points,
      elevations: elevations,
      distanceMeters: distance,
      ascentMeters: ascent,
      descentMeters: descent,
      steps: steps,
    );
  }

  static String _extractError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['error'] is Map) {
        final msg = (json['error'] as Map)['message'];
        if (msg != null) return msg.toString();
      }
      if (json is Map && json['error'] is String) {
        return json['error'] as String;
      }
    } catch (_) {}
    return '';
  }

  /// Computes ascent / descent from a sequence of per-point elevations.
  ///
  /// Applies a 5-point moving-average smoothing first because SRTM
  /// digital-elevation data carries roughly ±1 m noise. Then sums positive /
  /// negative deltas with a 0.5 m floor so that micro-fluctuations on flat
  /// stretches don't accumulate into fake elevation gain.
  static ({double ascent, double descent}) _ascentDescentFromElevations(
    List<double> elevations,
  ) {
    if (elevations.length < 2) return (ascent: 0, descent: 0);
    final smoothed = List<double>.filled(elevations.length, 0);
    for (var i = 0; i < elevations.length; i++) {
      final lo = (i - 2).clamp(0, elevations.length - 1);
      final hi = (i + 2).clamp(0, elevations.length - 1);
      var sum = 0.0;
      var n = 0;
      for (var j = lo; j <= hi; j++) {
        sum += elevations[j];
        n++;
      }
      smoothed[i] = sum / n;
    }
    const minStep = 0.5; // metres; smaller deltas are noise
    var ascent = 0.0;
    var descent = 0.0;
    var carry = 0.0;
    for (var i = 1; i < smoothed.length; i++) {
      carry += smoothed[i] - smoothed[i - 1];
      if (carry >= minStep) {
        ascent += carry;
        carry = 0;
      } else if (carry <= -minStep) {
        descent += -carry;
        carry = 0;
      }
    }
    return (ascent: ascent, descent: descent);
  }
}
