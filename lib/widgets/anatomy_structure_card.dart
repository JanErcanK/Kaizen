import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/stretch_exercise_catalog.dart';
import '../screens/stretch_catalog_screen.dart';
import '../services/anatomy_catalog.dart';
import '../theme/app_colors.dart';

class AnatomyStructureCard extends StatefulWidget {
  const AnatomyStructureCard({
    super.key,
    required this.info,
    required this.tissue,
    required this.onClose,
    this.bottomAnchored = false,
  });
  final AnatomyInfo info;
  final String tissue;
  final bool bottomAnchored;
  final VoidCallback onClose;

  @override
  State<AnatomyStructureCard> createState() => _AnatomyStructureCardState();
}

class _AnatomyStructureCardState extends State<AnatomyStructureCard> {
  bool _collapsed = false;

  Size? _size;
  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    final info = widget.info;
    final connective = widget.tissue == 'tendon' || widget.tissue == 'ligament';
    final stretches = stretchesForRegion(info.mobilityRegion);
    final tissueName = switch (widget.tissue) {
      'tendon' => de ? 'Sehne' : 'Tendon',
      'ligament' => de ? 'Band' : 'Ligament',
      'bone' => de ? 'Knochen' : 'Bone',
      'muscle' => de ? 'Muskel' : 'Muscle',
      _ => de ? 'Anatomie' : 'Anatomy',
    };
    return LayoutBuilder(
      builder: (context, bounds) {
        final maxW = bounds.hasBoundedWidth ? bounds.maxWidth : 420.0;
        final maxH = bounds.hasBoundedHeight ? bounds.maxHeight : 540.0;
        final width = (_size?.width ?? math.min(360.0, maxW * .9)).clamp(
          math.min(225.0, maxW),
          maxW,
        );
        final height = (_size?.height ?? math.min(380.0, maxH * .69)).clamp(
          math.min(170.0, maxH),
          maxH,
        );
        void resize(double dx, double dy) => setState(() {
          _size = Size(
            (width + dx).clamp(math.min(225.0, maxW), maxW),
            (height + dy).clamp(math.min(170.0, maxH), maxH),
          );
        });
        final grip = Semantics(
          label: de ? 'Kartengröße anpassen' : 'Resize card',
          slider: true,
          onIncrease: () => resize(24, 48),
          onDecrease: () => resize(-24, -48),
          child: MouseRegion(
            cursor: widget.bottomAnchored
                ? SystemMouseCursors.resizeUpRightDownLeft
                : SystemMouseCursors.resizeUpLeftDownRight,
            child: GestureDetector(
              key: const ValueKey('anatomy-resize'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => resize(
                d.delta.dx,
                widget.bottomAnchored ? -d.delta.dy : d.delta.dy,
              ),
              child: Container(
                alignment: Alignment.centerRight,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  widget.bottomAnchored
                      ? Icons.north_east_rounded
                      : Icons.south_east_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
        final title = Text(
          info.title(de),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            height: 1.16,
            fontWeight: FontWeight.w700,
          ),
        );
        return Container(
          key: const ValueKey('anatomy-structure-card'),
          width: width.toDouble(),
          height: _collapsed ? null : height.toDouble(),
          clipBehavior: Clip.antiAlias,
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Color.alphaBlend(
                    AppColors.primary.withValues(alpha: .13),
                    AppColors.card,
                  ),
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  child: Row(
                    children: [
                      Icon(
                        connective
                            ? Icons.gesture_rounded
                            : Icons.accessibility_new_rounded,
                        size: 17,
                        color: AppColors.accentText,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          tissueName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.accentText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.bottomAnchored && !_collapsed)
                        SizedBox(width: 42, child: grip),
                      IconButton(
                        tooltip: de
                            ? (_collapsed ? 'Vergrößern' : 'Verkleinern')
                            : (_collapsed ? 'Expand' : 'Collapse'),
                        icon: Icon(
                          _collapsed ? Icons.unfold_more : Icons.unfold_less,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _collapsed = !_collapsed),
                      ),
                      IconButton(
                        tooltip: de ? 'Schließen' : 'Close',
                        icon: const Icon(Icons.close_rounded, size: 19),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        if (!_collapsed) ...[
                          if (info.latinName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '(${info.latinName})',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            info.description(de),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          if (connective) ...[
                            const SizedBox(height: 18),
                            Divider(color: AppColors.stroke, height: 1),
                            const SizedBox(height: 14),
                            Text(
                              de
                                  ? 'Dehnen & Mobilität'
                                  : 'Stretching & mobility',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stretches.isEmpty
                                  ? (de
                                        ? 'Für diese Struktur gibt es hier keine passende Dehnempfehlung.'
                                        : 'There is no suitable stretching suggestion for this structure here.')
                                  : (de
                                        ? 'Für die umliegende Muskulatur. Bänder nicht gezielt dehnen. Kurz aufwärmen und nur sanften, schmerzfreien Zug zulassen.'
                                        : 'For the surrounding muscles. Do not deliberately stretch ligaments. Warm up first and allow only gentle, comfortable tension.'),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            for (final exercise in stretches)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ExpansionTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  collapsedBackgroundColor:
                                      AppColors.softSurface,
                                  backgroundColor: AppColors.softSurface,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    8,
                                  ),
                                  title: Text(
                                    exercise.name(de),
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  expandedCrossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.instructions(de),
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          startStretching(context, [exercise]),
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
                                      label: Text(
                                        de ? 'Übung starten' : 'Start exercise',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const StretchCatalogScreen(),
                                ),
                              ),
                              child: Text(
                                de
                                    ? 'Alle ${stretchExercises.length} Übungen'
                                    : 'All ${stretchExercises.length} exercises',
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (!widget.bottomAnchored && !_collapsed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 52, child: grip),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
