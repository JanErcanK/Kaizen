import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/calisthenics_exercise_catalog.dart';
import '../data/gym_exercise_catalog.dart';
import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/muscle_exercise_filter.dart';
import '../theme/app_colors.dart';
import '../utils/strength_add_exercise_flow.dart';
import 'body_overlay_painter.dart';
import 'muscle_segment_labels.dart';
import 'movable_anatomy_card.dart';

Rect? muscleSegmentBounds({
  required MuscleSegmentHit segment,
  required Size bodySize,
}) {
  final paths = transformedMusclePaths(bodySize, front: segment.front);
  final list = paths[segment.slug];
  if (list == null ||
      segment.pathIndex < 0 ||
      segment.pathIndex >= list.length) {
    return null;
  }
  return list[segment.pathIndex].getBounds();
}

Offset _computePopupTopLeft({
  required Size screenSize,
  required Size popupSize,
  required Rect? muscleRect,
}) {
  const margin = 12.0;
  const gap = 12.0;
  final muscle =
      muscleRect ??
      Rect.fromLTWH(
        screenSize.width * 0.35,
        screenSize.height * 0.25,
        screenSize.width * 0.3,
        screenSize.height * 0.35,
      );
  final inflated = muscle.inflate(10);

  final candidates = <Offset>[
    Offset(muscle.right + gap, muscle.center.dy - popupSize.height / 2),
    Offset(
      muscle.left - popupSize.width - gap,
      muscle.center.dy - popupSize.height / 2,
    ),
    Offset(
      muscle.center.dx - popupSize.width / 2,
      muscle.top - popupSize.height - gap,
    ),
    Offset(muscle.center.dx - popupSize.width / 2, muscle.bottom + gap),
    Offset(
      muscle.left - popupSize.width - gap,
      muscle.top - popupSize.height - gap,
    ),
    Offset(muscle.right + gap, muscle.top - popupSize.height - gap),
    Offset(muscle.left - popupSize.width - gap, muscle.bottom + gap),
    Offset(muscle.right + gap, muscle.bottom + gap),
    Offset(margin, margin),
    Offset(screenSize.width - popupSize.width - margin, margin),
    Offset(margin, screenSize.height - popupSize.height - margin),
    Offset(
      screenSize.width - popupSize.width - margin,
      screenSize.height - popupSize.height - margin,
    ),
  ];

  final minLeft = margin;
  final maxLeft = math.max(
    minLeft,
    screenSize.width - popupSize.width - margin,
  );
  final minTop = margin;
  final maxTop = math.max(
    minTop,
    screenSize.height - popupSize.height - margin,
  );
  Offset? best;
  var bestScore = double.infinity;
  for (final candidate in candidates) {
    final topLeft = Offset(
      candidate.dx.clamp(minLeft, maxLeft).toDouble(),
      candidate.dy.clamp(minTop, maxTop).toDouble(),
    );
    final rect = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      popupSize.width,
      popupSize.height,
    );
    final overlap = rect.intersect(inflated);
    final overlapArea = overlap.isEmpty ? 0.0 : overlap.width * overlap.height;
    final distance = (rect.center - muscle.center).distance;
    final score = distance + overlapArea * 4 + (overlapArea > 0 ? 10000 : 0);
    if (score < bestScore) {
      bestScore = score;
      best = topLeft;
    }
  }

  return best ?? Offset(minLeft, minTop);
}

/// Exercise picker shown when tapping a muscle on the expanded mannequin.
class MuscleExercisePopup extends StatefulWidget {
  const MuscleExercisePopup({
    super.key,
    required this.segment,
    required this.bodySize,
    this.muscleBounds,
    this.titleOverride,
    this.descriptionOverride,
    this.dockToBottom,
    this.dismissBarrier = true,
    required this.onClose,
  });

  final MuscleSegmentHit segment;
  final Size bodySize;
  final Rect? muscleBounds;

  /// Already localized labels supplied by the 3D anatomy catalog.
  final String? titleOverride;
  final String? descriptionOverride;
  final VoidCallback onClose;
  final bool? dockToBottom;
  final bool dismissBarrier;

  @override
  State<MuscleExercisePopup> createState() => _MuscleExercisePopupState();
}

class _MuscleExercisePopupState extends State<MuscleExercisePopup>
    with SingleTickerProviderStateMixin {
  bool _collapsed = false;
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.titleOverride?.trim().isNotEmpty ?? false) {
      return widget.titleOverride!;
    }
    final paths = transformedMusclePaths(
      widget.bodySize,
      front: widget.segment.front,
    );
    final german = Localizations.localeOf(context).languageCode == 'de';
    return muscleSegmentTitleForContext(
      widget.segment,
      widget.bodySize,
      paths,
      german,
    );
  }

  List<GymCatalogExercise> get _gymExercises =>
      MuscleExerciseFilter.gymExercisesFor(widget.segment);

  List<CalisthenicsCatalogExercise> get _caliExercises =>
      MuscleExerciseFilter.calisthenicsExercisesFor(widget.segment);

  Future<void> _addGym(GymCatalogExercise ex) async {
    await StrengthAddExerciseFlow.showAddOptions(
      context: context,
      kind: StrengthWorkoutKind.gym,
      displayName: CatalogLocalizations.gymExerciseName(ex.name),
      exercise: StrengthAddExerciseFlow.exerciseMap(
        name: ex.name,
        description: ex.description,
        mainGroup: ex.mainGroup,
        tags: ex.tags,
      ),
    );
  }

  Future<void> _addCali(CalisthenicsCatalogExercise ex) async {
    await StrengthAddExerciseFlow.showAddOptions(
      context: context,
      kind: StrengthWorkoutKind.calisthenics,
      displayName: CatalogLocalizations.calisthenicsExerciseName(ex.name),
      exercise: StrengthAddExerciseFlow.exerciseMap(
        name: ex.name,
        description: ex.description,
        mainGroup: ex.mainGroup,
        tags: ex.tags,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final screen = Size(
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : mediaSize.width,
          constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : mediaSize.height,
        );
        final availableWidth = math.max(
          0.0,
          screen.width - (widget.dismissBarrier ? 24 : 68),
        );
        final availableHeight = math.max(0.0, screen.height - 24);
        final popupWidth = math.min(
          availableWidth,
          math.min(340.0, screen.width * .76),
        );
        final popupHeight = math.min(
          availableHeight,
          (screen.height * (widget.dismissBarrier ? 0.50 : 0.42))
              .clamp(260.0, 400.0)
              .toDouble(),
        );
        final popupSize = Size(popupWidth, popupHeight);
        final muscleRect =
            widget.muscleBounds ??
            muscleSegmentBounds(
              segment: widget.segment,
              bodySize: widget.bodySize,
            );
        final topLeft = widget.dockToBottom != null
            ? Offset(
                12,
                widget.dockToBottom! ? screen.height - popupHeight - 12 : 12,
              )
            : _computePopupTopLeft(
                screenSize: screen,
                popupSize: popupSize,
                muscleRect: muscleRect,
              );

        return Stack(
          children: [
            if (widget.dismissBarrier)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(color: Colors.black.withValues(alpha: 0.12)),
                ),
              ),
            Positioned.fill(
              child: MovableAnatomyCard(
                key: ValueKey(
                  '${widget.segment.slug}:${widget.segment.pathIndex}:${widget.segment.front}',
                ),
                initialPosition: topLeft,
                child: SizedBox(
                  width: popupWidth,
                  height: _collapsed ? null : popupHeight,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      key: const ValueKey('anatomy-muscle-card'),
                      decoration: AppColors.surfaceDecoration(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 10, 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _collapsed = !_collapsed),
                                  tooltip: l10n.localeName.startsWith('de')
                                      ? (_collapsed
                                            ? 'Vergrößern'
                                            : 'Verkleinern')
                                      : (_collapsed ? 'Expand' : 'Collapse'),
                                  icon: Icon(
                                    _collapsed
                                        ? Icons.unfold_more
                                        : Icons.unfold_less,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onClose,
                                  tooltip: l10n.common_close,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_collapsed) ...[
                            if (widget.descriptionOverride?.trim().isNotEmpty ??
                                false)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  12,
                                ),
                                child: Text(
                                  widget.descriptionOverride!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                indicatorSize: TabBarIndicatorSize.label,
                                dividerColor: AppColors.stroke,
                                labelColor: AppColors.textPrimary,
                                unselectedLabelColor: AppColors.textMuted,
                                labelStyle: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                tabs: [
                                  Tab(
                                    height: 42,
                                    text: l10n.category_gym_title,
                                  ),
                                  Tab(
                                    height: 42,
                                    text: l10n.category_calisthenics_title,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _ExerciseList(
                                    emptyLabel: l10n.muscleExercise_emptyGym,
                                    itemCount: _gymExercises.length,
                                    itemBuilder: (context, i) {
                                      final ex = _gymExercises[i];
                                      return _ExerciseRow(
                                        name:
                                            CatalogLocalizations.gymExerciseName(
                                              ex.name,
                                            ),
                                        description:
                                            CatalogLocalizations.gymDescription(
                                              ex.name,
                                            ),
                                        tags: ex.tags,
                                        onAdd: () => _addGym(ex),
                                      );
                                    },
                                  ),
                                  _ExerciseList(
                                    emptyLabel:
                                        l10n.muscleExercise_emptyCalisthenics,
                                    itemCount: _caliExercises.length,
                                    itemBuilder: (context, i) {
                                      final ex = _caliExercises[i];
                                      return _ExerciseRow(
                                        name:
                                            CatalogLocalizations.calisthenicsExerciseName(
                                              ex.name,
                                            ),
                                        description:
                                            CatalogLocalizations.calisthenicsDescription(
                                              ex.name,
                                            ),
                                        tags: ex.tags
                                            .where(
                                              (t) => !t.startsWith('Skill:'),
                                            )
                                            .toList(),
                                        onAdd: () => _addCali(ex),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({
    required this.emptyLabel,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String emptyLabel;
  final int itemCount;
  final Widget? Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'Roboto',
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 12, 12),
      itemCount: itemCount,
      separatorBuilder: (_, _) =>
          Divider(height: 1, endIndent: 6, color: AppColors.stroke),
      itemBuilder: itemBuilder,
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.name,
    required this.description,
    required this.tags,
    required this.onAdd,
  });

  final String name;
  final String description;
  final List<String> tags;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final tag in tags.take(3))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            CatalogLocalizations.muscleTag(tag),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            tooltip: context.l10n.common_add,
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.stroke),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 19,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
