import 'dart:ui';

import 'body_overlay_painter.dart';

/// Identifies one drawable muscle polygon on the body map.
class MuscleSegmentHit {
  const MuscleSegmentHit({
    required this.slug,
    required this.pathIndex,
    required this.front,
  });

  final String slug;
  final int pathIndex;
  final bool front;

  @override
  bool operator ==(Object other) {
    return other is MuscleSegmentHit &&
        other.slug == slug &&
        other.pathIndex == pathIndex &&
        other.front == front;
  }

  @override
  int get hashCode => Object.hash(slug, pathIndex, front);
}

const Set<String> interactiveMuscleSlugs = {
  'chest',
  'obliques',
  'abs',
  'abs-upper',
  'abs-lower',
  'biceps',
  'triceps',
  'neck',
  'trapezius',
  'deltoids',
  'deltoids-anterior',
  'deltoids-lateral',
  'deltoids-posterior',
  'adductors',
  'quadriceps',
  'legs',
  'hamstring',
  'gluteal',
  'tibialis',
  'calves',
  'forearm',
  'upper-back',
  'lower-back',
};

MuscleSegmentHit? findMuscleSegmentAt({
  required Size size,
  required Offset pos,
  required bool front,
  required Map<String, List<Path>> paths,
}) {
  MuscleSegmentHit? best;
  var bestArea = double.infinity;

  for (final slug in interactiveMuscleSlugs) {
    final list = paths[slug];
    if (list == null) continue;
    for (var i = 0; i < list.length; i++) {
      final path = list[i];
      if (!path.contains(pos)) continue;
      final bounds = path.getBounds();
      final area = bounds.width * bounds.height;
      if (area < bestArea) {
        bestArea = area;
        best = MuscleSegmentHit(slug: slug, pathIndex: i, front: front);
      }
    }
  }

  return best;
}

int _comparePathVerticalThenHorizontal(
  Path a,
  Path b, {
  required bool leftSide,
}) {
  final ba = a.getBounds();
  final bb = b.getBounds();
  final dy = ba.center.dy.compareTo(bb.center.dy);
  if (dy != 0) return dy;
  return leftSide
      ? ba.center.dx.compareTo(bb.center.dx)
      : bb.center.dx.compareTo(ba.center.dx);
}

List<int> _indicesOnSameSide(List<Path> list, double bodyCenterX, bool isLeft) {
  final indices = <int>[];
  for (var i = 0; i < list.length; i++) {
    final left = list[i].getBounds().center.dx < bodyCenterX;
    if (left == isLeft) indices.add(i);
  }
  indices.sort(
    (a, b) =>
        _comparePathVerticalThenHorizontal(list[a], list[b], leftSide: isLeft),
  );
  return indices;
}

String _verticalPartEn(int rank, int total) {
  if (total <= 1) return '';
  if (total == 2) {
    return rank == 0 ? ' · upper' : ' · lower';
  }
  if (total == 3) {
    return switch (rank) {
      0 => ' · outer',
      1 => ' · middle',
      _ => ' · inner',
    };
  }
  if (total == 4) {
    return switch (rank) {
      0 => ' · upper',
      1 => ' · upper-middle',
      2 => ' · lower-middle',
      _ => ' · lower',
    };
  }
  return ' · segment ${rank + 1}';
}

String _verticalPartDe(int rank, int total) {
  if (total <= 1) return '';
  if (total == 2) {
    return rank == 0 ? ' · oben' : ' · unten';
  }
  if (total == 3) {
    return switch (rank) {
      0 => ' · außen',
      1 => ' · mitte',
      _ => ' · innen',
    };
  }
  if (total == 4) {
    return switch (rank) {
      0 => ' · oben',
      1 => ' · oben-mitte',
      2 => ' · unten-mitte',
      _ => ' · unten',
    };
  }
  return ' · Segment ${rank + 1}';
}

String _absSegmentTitleEn(MuscleSegmentHit hit, List<Path> list) {
  final sorted = List.generate(list.length, (i) => i);
  sorted.sort((a, b) {
    final ba = list[a].getBounds();
    final bb = list[b].getBounds();
    final rowA = (ba.center.dy / 24).round();
    final rowB = (bb.center.dy / 24).round();
    if (rowA != rowB) return rowA.compareTo(rowB);
    return ba.center.dx.compareTo(bb.center.dx);
  });
  final rank = sorted.indexOf(hit.pathIndex);
  const rows = ['upper', 'upper-middle', 'lower-middle', 'lower'];
  final row = (rank ~/ 2).clamp(0, rows.length - 1);
  final side = rank.isEven ? 'left' : 'right';
  return 'Rectus abdominis · ${rows[row]} · $side';
}

String _absSegmentTitleDe(MuscleSegmentHit hit, List<Path> list) {
  final sorted = List.generate(list.length, (i) => i);
  sorted.sort((a, b) {
    final ba = list[a].getBounds();
    final bb = list[b].getBounds();
    final rowA = (ba.center.dy / 24).round();
    final rowB = (bb.center.dy / 24).round();
    if (rowA != rowB) return rowA.compareTo(rowB);
    return ba.center.dx.compareTo(bb.center.dx);
  });
  final rank = sorted.indexOf(hit.pathIndex);
  const rows = ['oben', 'oben-mitte', 'unten-mitte', 'unten'];
  final row = (rank ~/ 2).clamp(0, rows.length - 1);
  final side = rank.isEven ? 'links' : 'rechts';
  return 'Gerader Bauchmuskel · ${rows[row]} · $side';
}

String muscleSegmentTitle(
  MuscleSegmentHit hit,
  Size size,
  Map<String, List<Path>> paths,
) {
  final regionTitle = trainingRegionTitle(hit.slug, german: false);
  if (regionTitle != null) return regionTitle;
  final layout = computeBodyLayout(size);
  final list = paths[hit.slug] ?? const <Path>[];
  if (hit.pathIndex < 0 || hit.pathIndex >= list.length) {
    return hit.slug;
  }

  if (hit.slug == 'abs') {
    return _absSegmentTitleEn(hit, list);
  }

  final bounds = list[hit.pathIndex].getBounds();
  final isLeft = bounds.center.dx < layout.bounds.center.dx;
  final sideEn = isLeft ? 'Left' : 'Right';

  final sameSideIndices = _indicesOnSameSide(
    list,
    layout.bounds.center.dx,
    isLeft,
  );
  final rank = sameSideIndices.indexOf(hit.pathIndex);
  final partEnSuffix = _verticalPartEn(rank, sameSideIndices.length);

  return switch (hit.slug) {
    'chest' =>
      isLeft
          ? 'Left pectoralis major$partEnSuffix'
          : 'Right pectoralis major$partEnSuffix',
    'deltoids' =>
      isLeft
          ? 'Left deltoid (shoulder)$partEnSuffix'
          : 'Right deltoid (shoulder)$partEnSuffix',
    'biceps' => '$sideEn biceps brachii$partEnSuffix',
    'triceps' => '$sideEn triceps brachii$partEnSuffix',
    'forearm' => '$sideEn forearm flexors/extensors$partEnSuffix',
    'obliques' => '$sideEn external oblique$partEnSuffix',
    'trapezius' => '$sideEn trapezius$partEnSuffix',
    'neck' => '$sideEn sternocleidomastoid / neck$partEnSuffix',
    'upper-back' => '$sideEn latissimus dorsi / rhomboids$partEnSuffix',
    'lower-back' => '$sideEn erector spinae$partEnSuffix',
    'quadriceps' => '$sideEn quadriceps$partEnSuffix',
    'hamstring' => '$sideEn hamstrings$partEnSuffix',
    'gluteal' => '$sideEn gluteus maximus$partEnSuffix',
    'adductors' => '$sideEn hip adductors$partEnSuffix',
    'calves' => '$sideEn gastrocnemius / soleus$partEnSuffix',
    'tibialis' => '$sideEn tibialis anterior$partEnSuffix',
    _ => '${hit.slug}$partEnSuffix',
  };
}

String muscleSegmentTitleDe(
  MuscleSegmentHit hit,
  Size size,
  Map<String, List<Path>> paths,
) {
  final regionTitle = trainingRegionTitle(hit.slug, german: true);
  if (regionTitle != null) return regionTitle;
  final layout = computeBodyLayout(size);
  final list = paths[hit.slug] ?? const <Path>[];
  if (hit.pathIndex < 0 || hit.pathIndex >= list.length) {
    return hit.slug;
  }

  if (hit.slug == 'abs') {
    return _absSegmentTitleDe(hit, list);
  }

  final bounds = list[hit.pathIndex].getBounds();
  final isLeft = bounds.center.dx < layout.bounds.center.dx;
  final sideDe = isLeft ? 'Links' : 'Rechts';

  final sameSideIndices = _indicesOnSameSide(
    list,
    layout.bounds.center.dx,
    isLeft,
  );
  final rank = sameSideIndices.indexOf(hit.pathIndex);
  final partDeSuffix = _verticalPartDe(rank, sameSideIndices.length);

  return switch (hit.slug) {
    'chest' =>
      isLeft
          ? 'Linker großer Brustmuskel (Pectoralis major)$partDeSuffix'
          : 'Rechter großer Brustmuskel (Pectoralis major)$partDeSuffix',
    'deltoids' => '$sideDe Deltamuskel (Schulter)$partDeSuffix',
    'biceps' => '$sideDe Bizeps (Biceps brachii)$partDeSuffix',
    'triceps' => '$sideDe Trizeps (Triceps brachii)$partDeSuffix',
    'forearm' => '$sideDe Unterarm (Flexoren/Extensoren)$partDeSuffix',
    'obliques' =>
      '$sideDe seitlicher Bauchmuskel (Obliquus externus)$partDeSuffix',
    'trapezius' => '$sideDe Trapezmuskel$partDeSuffix',
    'neck' => '$sideDe Nacken / Sternocleidomastoideus$partDeSuffix',
    'upper-back' =>
      '$sideDe oberer Rücken (Latissimus / Rhomboiden)$partDeSuffix',
    'lower-back' => '$sideDe Rückenstrecker (Erector spinae)$partDeSuffix',
    'quadriceps' => '$sideDe Quadrizeps$partDeSuffix',
    'hamstring' => '$sideDe Beinbeuger (Hamstrings)$partDeSuffix',
    'gluteal' => '$sideDe Gesäßmuskel (Gluteus maximus)$partDeSuffix',
    'adductors' => '$sideDe Adduktoren (innere Oberschenkel)$partDeSuffix',
    'calves' => '$sideDe Waden (Gastrocnemius / Soleus)$partDeSuffix',
    'tibialis' => '$sideDe Schienbeinmuskel (Tibialis anterior)$partDeSuffix',
    _ => '${hit.slug}$partDeSuffix',
  };
}

String muscleSegmentTitleForContext(
  MuscleSegmentHit hit,
  Size size,
  Map<String, List<Path>> paths,
  bool german,
) {
  return german
      ? muscleSegmentTitleDe(hit, size, paths)
      : muscleSegmentTitle(hit, size, paths);
}

/// Stable labels for 3D training regions without inventing 2D path subdivisions.
String? trainingRegionTitle(String slug, {required bool german}) {
  return switch (slug) {
    'abs-upper' =>
      german
          ? 'Gerader Bauchmuskel · obere Trainingsregion'
          : 'Rectus abdominis · upper training region',
    'abs-lower' =>
      german
          ? 'Gerader Bauchmuskel · untere Trainingsregion'
          : 'Rectus abdominis · lower training region',
    'deltoids-anterior' => german ? 'Vordere Schulter' : 'Anterior deltoid',
    'deltoids-lateral' => german ? 'Seitliche Schulter' : 'Lateral deltoid',
    'deltoids-posterior' => german ? 'Hintere Schulter' : 'Posterior deltoid',
    _ => null,
  };
}
