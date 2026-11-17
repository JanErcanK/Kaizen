import 'dart:convert';
import 'social_models.dart';
import 'route_activity.dart';

/// Validate remote content before it reaches local collections or widget casts.
/// Strip sender-local IDs and fields unrelated to the shared template.
Map<String, dynamic> normalizeSharedContent(
  ShareContentType type,
  Map<String, dynamic> payload,
) {
  if (utf8.encode(jsonEncode(payload)).length > 180000) {
    throw const FormatException('Shared content is too large');
  }
  String text(Object? value, int max, {bool required = false}) {
    if (value == null && !required) return '';
    if (value is! String ||
        value.length > max ||
        (required && value.trim().isEmpty)) {
      throw const FormatException('Invalid shared text');
    }
    return value.trim();
  }

  double number(Object? value, double max, {double min = 0}) {
    if (value is! num || !value.isFinite || value < min || value > max) {
      throw const FormatException('Invalid shared number');
    }
    return value.toDouble();
  }

  List<Map<String, dynamic>> maps(Object? value) {
    if (value is! List ||
        value.isEmpty ||
        value.length > 100 ||
        value.any((v) => v is! Map)) {
      throw const FormatException('Invalid shared items');
    }
    return value.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  final name = text(payload['name'], 160, required: true);
  switch (type) {
    case ShareContentType.thumbsUp:
      return {'name': '👍'};
    case ShareContentType.gymWorkout:
    case ShareContentType.calisthenicsWorkout:
      final exercises = maps(payload['exercises']).map((e) {
        final tags = e['tags'] ?? const [];
        if (tags is! List || tags.length > 50) {
          throw const FormatException('Invalid tags');
        }
        final timed = e.containsKey('setSeconds');
        final sets = e['sets'] ?? 3;
        final reps = e['reps'] ?? 10;
        final setReps = timed
            ? e['setSeconds']
            : e['setReps'] ??
                  List.filled(number(sets, 100, min: 1).toInt(), reps);
        if (setReps is! List || setReps.isEmpty || setReps.length > 100) {
          throw const FormatException('Invalid sets');
        }
        final normalizedReps = setReps.map((v) {
          if (v is! int) {
            throw const FormatException('Invalid repetition count');
          }
          return number(v, timed ? 3600 : 999, min: 1).toInt();
        }).toList();
        return {
          'name': text(e['name'], 160, required: true),
          'description': text(e['description'], 8000),
          'mainGroup': text(e['mainGroup'] ?? 'Other', 120),
          'tags': tags.map((v) => text(v, 120)).toList(),
          'sets': normalizedReps.length,
          if (timed)
            'setSeconds': normalizedReps
          else ...{
            'reps': normalizedReps.first,
            'setReps': normalizedReps,
          },
          'weight': number(e['weight'] ?? 0, 5000),
        };
      }).toList();
      return {'name': name, 'exercises': exercises};
    case ShareContentType.foodDish:
      final items = maps(payload['items']).map((e) {
        final grams = number(e['grams'], 10000, min: .01);
        final p = number(e['proteinG'], 10000);
        final c = number(e['carbsG'], 10000);
        final f = number(e['fatsG'], 10000);
        if (p + c + f > grams * 1.05) {
          throw const FormatException('Invalid food macros');
        }
        return {
          'foodName': text(e['foodName'], 160, required: true),
          'grams': grams,
          'proteinG': p,
          'carbsG': c,
          'fatsG': f,
          for (final key in [
            'fiberG',
            'sugarG',
            'satFatG',
            'cholesterolMg',
            'sodiumMg',
          ])
            if (e[key] != null) key: number(e[key], 10000000),
        };
      }).toList();
      return {
        'name': name,
        'description': text(payload['description'], 8000),
        'items': items,
      };
    case ShareContentType.runningRoute:
      List<List<double>> points(Object? value, {bool optional = false}) {
        if (value == null && optional) return [];
        if (value is! List ||
            value.length > 1000 ||
            (!optional && value.length < 2)) {
          throw const FormatException('Invalid route');
        }
        return value.map((p) {
          if (p is! List || p.length != 2) {
            throw const FormatException('Invalid point');
          }
          return [number(p[0], 90, min: -90), number(p[1], 180, min: -180)];
        }).toList();
      }
      final route = points(payload['points']);
      Map<String, dynamic>? activity;
      if (payload['activity'] != null) {
        final raw = payload['activity'];
        if (raw is! Map ||
            !RouteActivityType.values.any((type) => type.name == raw['type']) ||
            raw['elevationRecorded'] is! bool) {
          throw const FormatException('Invalid route activity');
        }
        final recordedAt = text(raw['recordedAt'], 40);
        if (recordedAt.isNotEmpty && DateTime.tryParse(recordedAt) == null) {
          throw const FormatException('Invalid activity date');
        }
        activity = {
          'type': raw['type'],
          'durationSeconds': number(
            raw['durationSeconds'] ?? 0,
            604800,
          ).toInt(),
          'descentMeters': number(raw['descentMeters'] ?? 0, 100000),
          'maxSpeedKmh': number(raw['maxSpeedKmh'] ?? 0, 500),
          'calories': number(raw['calories'] ?? 0, 100000).toInt(),
          'elevationRecorded': raw['elevationRecorded'],
          if (recordedAt.isNotEmpty) 'recordedAt': recordedAt,
        };
      }
      final rawSteps = payload['steps'] ?? const [];
      if (rawSteps is! List || rawSteps.length > 1000) {
        throw const FormatException('Invalid steps');
      }
      final steps = rawSteps.map((s) {
        if (s is! Map) throw const FormatException('Invalid step');
        return {
          'instruction': text(s['instruction'], 1000),
          'distanceMeters': number(s['distanceMeters'] ?? 0, 10000000),
          'endIndex': number(
            s['endIndex'] ?? 0,
            (route.length - 1).toDouble(),
          ).toInt(),
        };
      }).toList();
      return {
        'name': name,
        'points': route,
        'waypoints': points(payload['waypoints'], optional: true),
        'distanceMeters': number(payload['distanceMeters'] ?? 0, 10000000),
        'ascentMeters': number(payload['ascentMeters'] ?? 0, 10000000),
        'descentMeters': number(payload['descentMeters'] ?? 0, 10000000),
        'steps': steps,
        'activity': ?activity,
      };
  }
}
