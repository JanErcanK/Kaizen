import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/models/body_muscle_group.dart';
import 'package:kaizen/services/anatomy_catalog.dart';
import 'package:kaizen/services/muscle_exercise_filter.dart';
import 'package:kaizen/widgets/muscle_segment_labels.dart';

void main() {
  final json =
      jsonDecode(File(AnatomyCatalog.assetPath).readAsStringSync())
          as Map<String, dynamic>;
  final catalog = AnatomyCatalog.fromJson(json);

  test('the shipped muscle and organ manifests are completely mapped', () {
    final muscles =
        (jsonDecode(File('assets/models/muscle_ids.json').readAsStringSync())
                as Map<String, dynamic>)['groups']
            as List<dynamic>;
    final organs =
        (jsonDecode(File('assets/models/organ_ids.json').readAsStringSync())
                as Map<String, dynamic>)['groups']
            as List<dynamic>;
    expect(muscles.length, 102);
    for (final entry in muscles) {
      expect(
        catalog.muscle(entry['id'] as String),
        isNotNull,
        reason: entry['id'] as String,
      );
    }
    expect(organs.length, 28);
    for (final entry in organs) {
      expect(
        catalog.structures[entry['structure_id']]?.organId,
        entry['organ_id'],
      );
    }
  });

  test(
    'all atlas mappings use supported existing recovery groups and filters',
    () {
      expect(catalog.muscles.length, greaterThanOrEqualTo(102));
      for (final entry in catalog.muscles.values) {
        expect(
          BodyMuscleGroup.values.map((g) => g.name),
          contains(entry.canonicalGroup),
        );
        expect(
          MuscleExerciseFilter.mainGroupGermanForSlug(entry.trainingSegment),
          isNotNull,
          reason: entry.id,
        );
        expect(entry.nameDe, isNotEmpty);
        expect(entry.nameEn, isNotEmpty);
        expect(
          catalog.segment(entry.trainingSegment)?.canonicalGroup,
          entry.canonicalGroup,
        );
      }
    },
  );

  test('rectus training regions retain one canonical abdominal group', () {
    for (final side in ['l', 'r']) {
      for (final region in ['upper', 'lower']) {
        final id = 'rectus_abdominis.$region.$side';
        expect(catalog.muscle('muscle.$id')?.trainingSegment, 'abs-$region');
        expect(catalog.muscle(id)?.canonicalGroup, 'abs');
        final info = catalog.describe(id: id, tissue: 'muscle');
        expect(info.latinName, 'Musculus rectus abdominis');
        expect(info.descriptionDe, contains('der gesamte Muskel arbeitet mit'));
        expect(info.descriptionEn, contains('the whole muscle works together'));
      }
    }
    expect(catalog.muscle('rectus_abdominis.l')?.trainingSegment, 'abs');
  });

  test('named bone, tendon and organ cards remain educational information', () {
    final bone = catalog.describe(id: 'bone_femur_l', tissue: 'bone');
    expect(bone.title(true), 'Oberschenkelknochen – links');
    expect(bone.latinName, 'Femur');
    expect(
      catalog
          .describe(id: 'tendon.pectoralis_major.l', tissue: 'tendon')
          .descriptionDe,
      contains('Muskelzug'),
    );
    final heart = catalog.describe(
      id: 'heart',
      tissue: 'organ',
      organId: 'heart',
    );
    expect(heart.nameDe, 'Herz');
    expect(heart.latinName, 'Cor');
    expect(heart.descriptionEn, contains('Pumps blood'));
    final organs = catalog.structures.values.where(
      (info) => info.organId != null,
    );
    expect(organs.length, 28);
    for (final info in organs) {
      expect(info.nameDe, isNotEmpty);
      expect(info.nameEn, isNotEmpty);
      expect(info.descriptionDe, isNotEmpty);
      expect(info.descriptionEn, isNotEmpty);
    }
  });

  test('all three editable brain meshes resolve to the same brain card', () {
    for (final part in ['brain', 'cerebellum', 'brainstem']) {
      final info = catalog.describe(
        id: 'organ.$part',
        tissue: 'organ',
        organId: part, // Also handles a stale renderer sending an old part ID.
      );
      expect(info, same(catalog.structures['organ.brain']));
      expect(info.organId, 'brain');
      expect(info.nameDe, 'Gehirn');
      expect(info.nameEn, 'Brain');
      expect(info.latinName, 'Encephalon');
    }
    expect(
      catalog.structures.values
          .where((info) => info.organId != null)
          .map((info) => info.organId)
          .toSet()
          .length,
      26,
    );
  });

  test(
    'connective participation uses explicit named anatomical associations',
    () {
      final groups = BodyMuscleGroup.values.map((g) => g.name).toSet();
      for (final entry in catalog.structures.entries) {
        expect(
          groups.containsAll(entry.value.trainingGroups),
          isTrue,
          reason: entry.key,
        );
        if (entry.key.startsWith('bone_') || entry.key.startsWith('organ.')) {
          expect(entry.value.trainingGroups, isEmpty, reason: entry.key);
        }
      }
      expect(catalog.structures['tendon_calcaneal_tendon_l']!.trainingGroups, [
        'legs',
      ]);
      expect(
        catalog
            .structures['ligament_anterior_cruciate_ligament_l']!
            .trainingGroups,
        ['legs'],
      );
      expect(
        catalog.structures['cartilage_medial_meniscus_l']!.trainingGroups,
        ['legs'],
      );
      expect(catalog.structures['tendon.pectoralis_major.l']!.trainingGroups, [
        'chest',
      ]);
      expect(
        catalog.structures['cartilage_glenoid_labrum_l']!.trainingGroups,
        contains('shoulders'),
      );
      expect(
        catalog
            .structures['ligament_lateral_temporomandibular_ligament_l']!
            .trainingGroups,
        isEmpty,
      );
      expect(
        catalog
            .structures['cartilage_costal_cartilage_of_first_rib_l']!
            .trainingGroups,
        isEmpty,
      );
    },
  );

  test(
    'unknown structures and missing config have honest tissue fallbacks',
    () {
      final info = const AnatomyCatalog.empty().describe(
        id: 'not-in-catalog',
        tissue: 'ligament',
        name: 'Example ligament',
      );
      expect(info.nameEn, 'Example ligament');
      expect(info.latinName, 'Ligamentum');
      expect(info.descriptionDe, contains('stabilisieren'));
      expect(catalog.muscle('unknown'), isNull);
      expect(
        () => AnatomyCatalog.fromJson({...json, 'schemaVersion': 2}),
        throwsFormatException,
      );
    },
  );

  test('catalog rejects a muscle with a mismatching recovery group', () {
    final changed = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    changed['muscles']['rectus_abdominis.upper.l']['canonicalGroup'] = 'legs';
    expect(() => AnatomyCatalog.fromJson(changed), throwsFormatException);
  });

  test('3D labels work without a 2D path index', () {
    expect(
      trainingRegionTitle('abs-upper', german: true),
      contains('Trainingsregion'),
    );
    expect(
      trainingRegionTitle('deltoids-posterior', german: false),
      'Posterior deltoid',
    );
  });
}
