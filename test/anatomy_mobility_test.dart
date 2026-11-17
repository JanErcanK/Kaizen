import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/stretch_exercise_catalog.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/stretch_catalog_screen.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/screens/workout_player_screen.dart';
import 'package:kaizen/services/anatomy_catalog.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/anatomy_structure_card.dart';

void main() {
  final raw =
      jsonDecode(File(AnatomyCatalog.assetPath).readAsStringSync())
          as Map<String, dynamic>;
  final catalog = AnatomyCatalog.fromJson(raw);
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_mobility_');
    await ProgressStore.init(storageRootPath: storage.path);
    if (Platform.environment['ANATOMY_CAPTURE'] == '1') {
      final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/${font.value}',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      }
    }
  });
  tearDownAll(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  test(
    'all shipped bones have functional, bilingual copy without mesh labels',
    () {
      final bones = catalog.structures.entries.where(
        (e) => e.key.startsWith('bone_'),
      );
      expect(bones.length, 232);
      for (final e in bones) {
        expect(
          e.value.nameEn,
          isNot(matches(RegExp(r'\.[lr]$'))),
          reason: e.key,
        );
        expect(
          e.value.descriptionEn,
          isNot(contains('Bones support the body')),
        );
        expect(
          e.value.descriptionDe,
          isNot(contains('Knochen tragen den Körper')),
        );
      }
      expect(catalog.structures['bone_femur_l']!.nameEn, 'Thigh bone – left');
      expect(
        catalog.structures['bone_sacrum']!.descriptionDe,
        contains('Becken'),
      );
      expect(
        catalog.structures['bone_ulna_r']!.descriptionDe,
        contains('Ellenbogen'),
      );
      expect(
        catalog.structures['bone_scaphoid_bone_r']!.nameDe,
        contains('Handgelenk'),
      );
    },
  );

  test(
    'every tendon and ligament has a body-region mapping and technical subtitle',
    () {
      final structures = raw['structures'] as Map<String, dynamic>;
      for (final e in structures.entries) {
        if (!['tendon', 'ligament'].contains(e.value['tissue'])) continue;
        final info = catalog.structures[e.key]!;
        expect(info.mobilityRegion, isNotNull, reason: e.key);
        expect(
          info.latinName,
          isNot(anyOf('Tendo', 'Ligamentum')),
          reason: e.key,
        );
        expect(
          info.nameEn,
          isNot(contains('Tendinous component')),
          reason: e.key,
        );
        if (info.mobilityRegion != 'jaw') {
          expect(
            stretchesForRegion(info.mobilityRegion),
            isNotEmpty,
            reason: e.key,
          );
        }
      }
      List<String> ids(String id) => stretchesForRegion(
        catalog.structures[id]!.mobilityRegion,
      ).map((e) => e.id).toList();
      expect(
        ids('tendon_tendinous_component_of_gluteus_medius_muscle_l'),
        contains('pigeon_supported'),
      );
      expect(
        ids('ligament_anterior_longitudinal_ligament'),
        contains('Spinal_Stretch'),
      );
      expect(
        ids('tendon_tendinous_component_of_pectineus_muscle_l'),
        contains('Adductor_Groin'),
      );
      expect(
        ids('tendon_tendinous_component_of_vastus_intermedius_muscle_l'),
        contains('standing_quad'),
      );
      expect(ids('ligament_lateral_temporomandibular_ligament_l'), isEmpty);
    },
  );

  test('stretch library has 50+ distinct exercises and bilingual search', () {
    expect(stretchExercises.length, greaterThanOrEqualTo(50));
    expect(
      stretchExercises.map((e) => e.id).toSet().length,
      stretchExercises.length,
    );
    expect(
      stretchExercises.map((e) => e.nameDe).toSet().length,
      stretchExercises.length,
    );
    expect(
      stretchExercises.where((e) => e.matches('pigeon')).single.id,
      'pigeon_supported',
    );
    expect(stretchExercises.where((e) => e.matches('Nacken')), isNotEmpty);
    expect(stretchExercises.where((e) => e.matches('neck')), isNotEmpty);
    expect(stretchesForRegion(null), isEmpty);
  });

  Widget host(Widget child, {bool de = true, double scale = 1}) => MaterialApp(
    theme: ThemeData(fontFamily: 'Roboto'),
    locale: Locale(de ? 'de' : 'en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(body: child),
  );

  for (final de in [true, false]) {
    testWidgets(
      'specific tendon card fits large text and collapses (${de ? 'de' : 'en'})',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var closed = false;
        final captureKey = GlobalKey();
        await tester.pumpWidget(
          host(
            RepaintBoundary(
              key: captureKey,
              child: Center(
                child: SizedBox(
                  width: 290,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: AnatomyStructureCard(
                      info: catalog
                          .structures['tendon_tendinous_component_of_pectineus_muscle_l']!,
                      tissue: 'tendon',
                      onClose: () => closed = true,
                    ),
                  ),
                ),
              ),
            ),
            de: de,
            scale: 1.3,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            de
                ? 'Sehne · Oberschenkel innen – links'
                : 'Inner thigh tendon – left',
          ),
          findsOneWidget,
        );
        expect(
          find.text(de ? 'Schmetterling im Sitzen' : 'Adductor/Groin'),
          findsOneWidget,
        );
        if (Platform.environment['ANATOMY_CAPTURE'] == '1') {
          final boundary =
              captureKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              'output/anatomy_details_${de ? 'de' : 'en'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        final card = find.byKey(const ValueKey('anatomy-structure-card'));
        final initial = tester.getSize(card);
        final grip = find.byKey(const ValueKey('anatomy-resize'));
        await tester.drag(grip, const Offset(30, 70));
        await tester.pumpAndSettle();
        expect(tester.getSize(card).height, greaterThan(initial.height));
        await tester.drag(grip, const Offset(-40, -90));
        await tester.pumpAndSettle();
        expect(tester.getSize(card).height, lessThan(initial.height));
        await tester.tap(find.byTooltip(de ? 'Verkleinern' : 'Collapse'));
        await tester.pumpAndSettle();
        expect(
          find.text(de ? 'Dehnen & Mobilität' : 'Stretching & mobility'),
          findsNothing,
        );
        await tester.tap(find.byTooltip(de ? 'Vergrößern' : 'Expand'));
        await tester.pumpAndSettle();
        expect(
          find.text(de ? 'Dehnen & Mobilität' : 'Stretching & mobility'),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip(de ? 'Schließen' : 'Close'));
        expect(closed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'workout search opens the matching stretch and starts a timed exercise',
    (tester) async {
      await tester.pumpWidget(host(const WorkoutHubScreen(), de: false));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'pigeon');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supported Pigeon Stretch'));
      await tester.pumpAndSettle();
      expect(find.byType(StretchCatalogScreen), findsOneWidget);
      await tester.tap(find.text('Supported Pigeon Stretch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start 30 seconds'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final player = tester.widget<WorkoutPlayerScreen>(
        find.byType(WorkoutPlayerScreen),
      );
      expect(player.workoutType, 'stretch');
      expect(player.exercises.single.workSeconds, 30);
      expect(player.exercises.single.benefit, contains('cushion'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
