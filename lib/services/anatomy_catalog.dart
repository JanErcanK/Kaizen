import 'dart:convert';

import 'package:flutter/services.dart';

/// Localized, educational atlas information. It does not assess tissue health.
class AnatomyInfo {
  const AnatomyInfo({
    required this.nameDe,
    required this.nameEn,
    required this.latinName,
    required this.descriptionDe,
    required this.descriptionEn,
    this.organId,
    this.trainingGroups = const [],
    this.trainingRelation,
    this.mobilityRegion,
  });

  factory AnatomyInfo.fromJson(Map<String, dynamic> json) => AnatomyInfo(
    nameDe: json['nameDe'] as String? ?? '',
    nameEn: json['nameEn'] as String? ?? '',
    latinName: json['latinName'] as String? ?? '',
    descriptionDe: json['descriptionDe'] as String? ?? '',
    descriptionEn: json['descriptionEn'] as String? ?? '',
    organId: json['organId'] as String?,
    trainingGroups: List<String>.unmodifiable(
      (json['trainingGroups'] as List<dynamic>? ?? const []).cast<String>(),
    ),
    trainingRelation: json['trainingRelation'] as String?,
    mobilityRegion: json['mobilityRegion'] as String?,
  );

  final String nameDe;
  final String nameEn;
  final String latinName;
  final String descriptionDe;
  final String descriptionEn;
  final String? organId;

  /// Possible participation inferred from named anatomy, not tissue recovery.
  final List<String> trainingGroups;
  final String? trainingRelation;
  final String? mobilityRegion;

  String title(bool german) => german ? nameDe : nameEn;
  String description(bool german) => german ? descriptionDe : descriptionEn;
}

class AnatomyMuscle {
  const AnatomyMuscle({
    required this.id,
    required this.trainingSegment,
    required this.canonicalGroup,
    required this.nameDe,
    required this.nameEn,
    this.latinName = '',
  });

  final String id;
  final String trainingSegment;

  /// Existing BodyMuscleGroup.name; training regions do not add recovery groups.
  final String canonicalGroup;
  final String nameDe;
  final String nameEn;
  final String latinName;
}

class AnatomySegment {
  const AnatomySegment({required this.canonicalGroup, required this.info});
  final String canonicalGroup;
  final AnatomyInfo info;
  String get nameDe => info.nameDe;
  String get nameEn => info.nameEn;
  String get descriptionDe => info.descriptionDe;
  String get descriptionEn => info.descriptionEn;
}

/// Shared JSON is consumed by Flutter and the embedded 3D viewer.
class AnatomyCatalog {
  const AnatomyCatalog.empty()
    : muscles = const {},
      segments = const {},
      structures = const {};

  const AnatomyCatalog._(this.muscles, this.segments, this.structures);

  static const assetPath = 'assets/3d_viewer/anatomy_config.json';

  static Future<AnatomyCatalog> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return AnatomyCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory AnatomyCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported anatomy catalog schema');
    }
    Map<String, Map<String, dynamic>> table(String key) {
      final value = json[key];
      if (value is! Map) throw FormatException('Missing anatomy table: $key');
      return value.map(
        (key, value) =>
            MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
      );
    }

    final muscles = table('muscles').map(
      (id, value) => MapEntry(
        id,
        AnatomyMuscle(
          id: id,
          trainingSegment: value['trainingSegment'] as String,
          canonicalGroup: value['canonicalGroup'] as String,
          nameDe: value['nameDe'] as String,
          nameEn: value['nameEn'] as String,
          latinName: value['latinName'] as String? ?? '',
        ),
      ),
    );
    final segments = table('segments').map(
      (id, value) => MapEntry(
        id,
        AnatomySegment(
          canonicalGroup: value['canonicalGroup'] as String,
          info: AnatomyInfo.fromJson(value),
        ),
      ),
    );
    for (final muscle in muscles.values) {
      if (segments[muscle.trainingSegment]?.canonicalGroup !=
          muscle.canonicalGroup) {
        throw FormatException('Invalid training segment for ${muscle.id}');
      }
    }
    return AnatomyCatalog._(
      Map.unmodifiable(muscles),
      Map.unmodifiable(segments),
      Map.unmodifiable(
        table(
          'structures',
        ).map((id, value) => MapEntry(id, AnatomyInfo.fromJson(value))),
      ),
    );
  }

  final Map<String, AnatomyMuscle> muscles;
  final Map<String, AnatomySegment> segments;
  final Map<String, AnatomyInfo> structures;

  AnatomyMuscle? muscle(String id) =>
      muscles[id.replaceFirst(RegExp(r'^muscle\.'), '')];
  AnatomySegment? segment(String? id) => segments[id];

  AnatomyInfo describe({
    required String id,
    required String tissue,
    String? name,
    String? nameLatin,
    String? organId,
    String? trainingSegment,
  }) {
    if (tissue == 'muscle') {
      final entry = muscle(id);
      final region = segment(entry?.trainingSegment ?? trainingSegment);
      final generic = _fallback('muscle');
      return AnatomyInfo(
        nameDe: entry?.nameDe ?? name ?? region?.nameDe ?? generic.nameDe,
        nameEn: entry?.nameEn ?? name ?? region?.nameEn ?? generic.nameEn,
        latinName: entry?.latinName ?? nameLatin ?? generic.latinName,
        descriptionDe: region?.descriptionDe ?? generic.descriptionDe,
        descriptionEn: region?.descriptionEn ?? generic.descriptionEn,
      );
    }
    final entry =
        structures[id] ??
        structures['$tissue.$id'] ??
        structures[organId] ??
        structures['organ.$organId'];
    if (entry != null) {
      // Several editable meshes can describe one selectable organ.
      if (tissue == 'organ' && entry.organId != null) {
        return structures['organ.${entry.organId}'] ?? entry;
      }
      return entry;
    }
    final generic = _fallback(tissue);
    return AnatomyInfo(
      nameDe: name ?? generic.nameDe,
      nameEn: name ?? generic.nameEn,
      latinName: nameLatin ?? generic.latinName,
      descriptionDe: generic.descriptionDe,
      descriptionEn: generic.descriptionEn,
      organId: organId,
    );
  }

  static AnatomyInfo _fallback(String tissue) {
    final value = switch (tissue) {
      'bone' => const [
        'Knochen',
        'Bone',
        'Os',
        'Knochen bilden das tragende Gerüst des Körpers und dienen als Ansatz für Muskeln.',
        'Bones form the supporting framework of the body and provide muscle attachments.',
      ],
      'cartilage' => const [
        'Knorpel',
        'Cartilage',
        'Cartilago',
        'Knorpel ist formgebendes, druckbelastbares Bindegewebe. Gelenkknorpel unterstützt gleitende Bewegungen.',
        'Cartilage is connective tissue that supports shape and bears compression. Articular cartilage supports gliding movement.',
      ],
      'tendon' => const [
        'Sehnengewebe',
        'Tendon tissue',
        'Tendo',
        'Sehnengewebe überträgt Muskelzug. Flächige Sehnen werden Aponeurosen genannt.',
        'Tendon tissue transmits muscle force. Broad sheets of tendon are called aponeuroses.',
      ],
      'ligament' => const [
        'Bandstruktur',
        'Ligament',
        'Ligamentum',
        'Bänder verbinden und stabilisieren anatomische Strukturen und führen Gelenkbewegungen.',
        'Ligaments connect and stabilize anatomical structures and guide joint movement.',
      ],
      'organ' => const [
        'Organ',
        'Organ',
        'Organum',
        'Ein Organ übernimmt spezialisierte Aufgaben innerhalb eines Organsystems.',
        'An organ performs specialized tasks within an organ system.',
      ],
      'muscle' => const [
        'Muskel',
        'Muscle',
        'Musculus',
        'Muskeln erzeugen Bewegung und unterstützen die Haltung. Übungen beanspruchen mehrere Muskeln gemeinsam.',
        'Muscles produce movement and support posture. Exercises involve several muscles together.',
      ],
      _ => const [
        'Körperstruktur',
        'Body structure',
        '',
        'Anatomische Struktur des Körpermodells.',
        'An anatomical structure of the body model.',
      ],
    };
    return AnatomyInfo(
      nameDe: value[0],
      nameEn: value[1],
      latinName: value[2],
      descriptionDe: value[3],
      descriptionEn: value[4],
    );
  }
}
