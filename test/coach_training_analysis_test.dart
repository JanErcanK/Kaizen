import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/models/health_dashboard.dart';
import 'package:kaizen/services/ai_chat_service.dart';
import 'package:kaizen/services/coach_context_service.dart';
import 'package:kaizen/services/coach_training_analysis.dart';
import 'package:kaizen/services/progress_store.dart';

Map<String, dynamic> session(
  DateTime at, {
  String name = 'Bench press',
  List<int> reps = const [10, 10, 10],
  double? load = 40,
}) => {
  'id': at.toIso8601String(),
  'recordedAt': at.toIso8601String(),
  'type': 'gym',
  'durationSeconds': 1800,
  'exercises': [
    {
      'name': name,
      'mainGroup': 'Brust',
      'tags': ['Trizeps'],
      'setReps': reps,
      'weight': ?load,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 25, 18);

  test(
    'all 80 sessions are aggregated in calendar windows, independent of input order',
    () {
      final events = List.generate(
        80,
        (i) => session(DateTime(2026, 10, 25 - i % 56, 12)),
      );
      final result = CoachTrainingAnalysis.analyze(
        events.reversed.toList(),
        now: now,
      );
      expect(result['from'], '2026-08-31');
      expect(result['through'], '2026-10-25');
      expect(result['recordedSessions'], 80);
      final weeks = result['weeks'] as List;
      expect(weeks, hasLength(8));
      expect(weeks.fold<int>(0, (sum, w) => sum + (w['sessions'] as int)), 80);
      expect(weeks.last['through'], '2026-10-25');
      final comparison = result['fourWeekComparison'] as Map;
      expect(
        comparison['previous']['sessions'] + comparison['recent']['sessions'],
        80,
      );
      expect(weeks.first['directMuscleSets'].containsKey('Trizeps'), isFalse);
    },
  );

  test(
    'boundary, future and undated sessions cannot distort the comparison',
    () {
      final result = CoachTrainingAnalysis.analyze([
        session(DateTime(2026, 8, 31)),
        session(DateTime(2026, 9, 27, 23, 59)),
        session(DateTime(2026, 9, 28)),
        session(now),
        session(DateTime(2026, 8, 30, 23, 59)),
        session(now.add(const Duration(seconds: 1))),
        {'recordedAt': 'broken'},
      ], now: now);
      expect(result['recordedSessions'], 4);
      expect(result['excludedUndatedRecords'], 1);
      expect(result['fourWeekComparison']['previous']['sessions'], 2);
      expect(result['fourWeekComparison']['recent']['sessions'], 2);
    },
  );

  test('rep progression requires matching recorded loads and set counts', () {
    Map trend(List<Map<String, dynamic>> records) =>
        (CoachTrainingAnalysis.analyze(records, now: now)['exerciseTrends']
                    as List)
                .single
            as Map;
    final first = session(DateTime(2026, 9, 1), reps: [8, 8, 8]);
    final latest = session(DateTime(2026, 10, 24), reps: [10, 10, 10]);
    final matching = trend([latest, first]);
    expect(matching['repChangeAtSameLoadAndSets'], 6);
    expect(matching['first']['externalLoadVolumeKg'], 960);
    expect(matching['latest']['externalLoadVolumeKg'], 1200);
    expect(
      trend([
        first,
        session(DateTime(2026, 10, 24), load: 50),
      ])['repChangeAtSameLoadAndSets'],
      isNull,
    );
    expect(
      trend([
        session(DateTime(2026, 9, 1), load: null),
        session(DateTime(2026, 10, 24), load: null),
      ])['sameLoadAndSetCount'],
      isFalse,
    );
  });

  test(
    'missing reps, zero reps and nonfinite loads do not invent training volume',
    () {
      final event = session(now, reps: [10, 0, 8], load: double.nan);
      (event['exercises'] as List).add({
        'name': 'Unknown',
        'mainGroup': 'Beine',
      });
      final result = CoachTrainingAnalysis.analyze([event], now: now);
      expect(result['weeks'].last['directMuscleSets'], {'Brust': 2});
      final trends = result['exerciseTrends'] as List;
      expect(trends.first['latest']['recordedReps'], 18);
      expect(trends.first['latest']['externalLoadVolumeKg'], isNull);
      expect(trends.last['latest']['recordedSets'], 0);
    },
  );

  test(
    'nutrition averages use logged days and missing duration stays unknown',
    () {
      final event = session(now)..remove('durationSeconds');
      final result = CoachTrainingAnalysis.analyze(
        [event],
        now: now,
        nutrition: [
          {'day': '2026-10-24', 'logged': true, 'kcal': 2000, 'proteinG': 100},
          {'day': '2026-10-25', 'logged': false, 'kcal': 0, 'proteinG': 0},
        ],
        weights: [
          {'date': '2026-10-24', 'weight': 75},
        ],
      );
      final week = result['weeks'].last;
      expect(week['durationMinutes'], isNull);
      expect(week['nutritionLoggedDays'], 1);
      expect(week['meanLoggedKcal'], 2000);
      expect(week['meanWeightKg'], 75);
      expect(result['fourWeekComparison']['sessionChangePercent'], isNull);
    },
  );

  test(
    'run pace weights distance and excludes records without paired duration',
    () {
      final result = CoachTrainingAnalysis.analyze([
        {
          'recordedAt': now.toIso8601String(),
          'type': 'run',
          'runMeters': 5000,
          'durationSeconds': 1500,
        },
        {
          'recordedAt': now.toIso8601String(),
          'type': 'run',
          'runMeters': 10000,
          'durationSeconds': 3600,
        },
        {'recordedAt': now.toIso8601String(), 'type': 'run', 'runMeters': 1000},
      ], now: now);
      final week = result['weeks'].last;
      expect(week['runKm'], 16);
      expect(week['runPaceMinPerKm'], 5.7);
      expect(week['runsWithDistanceAndDuration'], 2);
    },
  );

  group('context integration', () {
    late Directory temp;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('coach_analysis_');
      await ProgressStore.init(storageRootPath: temp.path);
    });
    tearDown(() async {
      await ProgressStore.closeForTesting();
      await temp.delete(recursive: true);
    });

    test(
      'opt-in gates analysis and new lookups; snapshots refresh and notes stay unchanged',
      () async {
        expect(
          CoachContextService.snapshot(),
          isNot(contains('trainingAnalysis')),
        );
        expect(
          CoachContextService.query('trainingAnalysis', 0),
          contains('disabled'),
        );
        await ProgressStore.saveChatSettings({'shareFitnessContext': true});
        expect(
          jsonDecode(
            CoachContextService.snapshot(),
          )['trainingAnalysis']['recordedSessions'],
          0,
        );
        final at = DateTime.now().subtract(const Duration(days: 30));
        await ProgressStore.addWorkoutEvent(
          type: 'gym',
          recordedAt: at,
          exercises: [
            {
              'name': 'Rows',
              'mainGroup': 'Rücken',
              'sets': 4,
              'reps': 8,
              'weight': 35,
            },
          ],
        );
        final snapshot = jsonDecode(CoachContextService.snapshot());
        expect(snapshot['trainingAnalysis']['recordedSessions'], 1);
        expect(
          snapshot['trainingAnalysis']['fourWeekComparison']['previous']['sessions'],
          1,
        );
        final lookup = jsonDecode(
          CoachContextService.query('trainingAnalysis', 0, search: 'Rows'),
        );
        expect(lookup['records'].single['name'], 'Rows');
        expect(
          AiChatAction.fromJson({
            'type': 'read_fitness_data',
            'dataSection': 'trainingAnalysis',
          }).type,
          AiChatActionType.readFitnessData,
        );
        expect(CoachContextService.memories, isEmpty);
      },
    );

    test(
      'health trend means retain source separation and measurement coverage',
      () async {
        final day = DateTime.now();
        await ProgressStore.saveChatSettings({'shareFitnessContext': true});
        await ProgressStore.saveHealthDashboard(
          HealthDashboardSnapshot(
            metrics: {
              HealthMetric.sleep: HealthMetricData(
                state: HealthReadState.available,
                series: [
                  for (final minutes in [420.0, 480.0])
                    HealthSeries(
                      sourceId: '$minutes',
                      source: 'source $minutes',
                      days: [
                        HealthDayValue(
                          day: day,
                          value: minutes,
                          recordedAt: day,
                        ),
                      ],
                    ),
                ],
              ),
            },
          ),
        );
        final health =
            jsonDecode(CoachContextService.snapshot())['healthTrends'] as List;
        expect(health, hasLength(2));
        expect(health.map((h) => h['periods'][0]['mean']), [420, 480]);
        expect(health.first['periods'][0]['measuredDays'], 1);
        expect(health.first['periods'][1]['mean'], isNull);
      },
    );

    for (final provider in AiProvider.values) {
      test(
        '${provider.name} receives aggregate evidence and supports a trend lookup',
        () async {
          await ProgressStore.saveChatSettings({'shareFitnessContext': true});
          var calls = 0;
          final service = AiChatService(
            client: MockClient((request) async {
              final body = jsonDecode(request.body);
              final instructions =
                  body[provider == AiProvider.openai
                          ? 'instructions'
                          : 'system']
                      as String;
              expect(instructions, contains('fourWeekComparison'));
              expect(instructions, contains('2-4 prioritized'));
              calls++;
              final payload = jsonEncode({
                'reply': calls == 1
                    ? 'Read trends'
                    : 'No sessions recorded yet.',
                'action': calls == 1
                    ? {
                        'type': 'read_fitness_data',
                        'dataSection': 'trainingAnalysis',
                      }
                    : {'type': 'none'},
              });
              return http.Response(
                jsonEncode(
                  provider == AiProvider.openai
                      ? {
                          'status': 'completed',
                          'output': [
                            {
                              'type': 'message',
                              'content': [
                                {'type': 'output_text', 'text': payload},
                              ],
                            },
                          ],
                        }
                      : {
                          'stop_reason': 'end_turn',
                          'content': [
                            {'type': 'text', 'text': payload},
                          ],
                        },
                ),
                200,
              );
            }),
          );
          final reply = await service.send(
            provider: provider,
            model: 'test',
            apiKey: 'test',
            messages: [
              ChatMessage(
                id: 'question',
                role: 'user',
                text: 'Improve my training',
                createdAt: DateTime.now(),
              ),
            ],
            language: 'English',
          );
          expect(reply.text, 'No sessions recorded yet.');
          expect(calls, 2);
        },
      );
    }
  });
}
