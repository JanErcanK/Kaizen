import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'organ_guidance_panel.dart';

/// Keeps everyday actions visible when an organ is picked in the 3D atlas.
class OrganDetailCard extends StatefulWidget {
  const OrganDetailCard({
    super.key,
    required this.organId,
    required this.title,
    required this.description,
    required this.latinName,
    required this.height,
    required this.onClose,
  });

  final String organId, title, description, latinName;
  final double height;
  final VoidCallback onClose;

  @override
  State<OrganDetailCard> createState() => _OrganDetailCardState();
}

class _OrganDetailCardState extends State<OrganDetailCard> {
  final _scroll = ScrollController();
  bool _collapsed = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    return Container(
      key: const ValueKey('anatomy-organ-card'),
      height: _collapsed ? null : widget.height,
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                    tooltip: de
                        ? (_collapsed ? 'Vergrößern' : 'Verkleinern')
                        : (_collapsed ? 'Expand' : 'Collapse'),
                    icon: Icon(
                      _collapsed ? Icons.unfold_more : Icons.unfold_less,
                      color: AppColors.textMuted,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    tooltip: de ? 'Schließen' : 'Close',
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!_collapsed)
              Expanded(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    key: ValueKey('organ-content-${widget.organId}'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrganGuidancePanel(
                          organId: widget.organId,
                          prioritizeActions: true,
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          title: Text(
                            de ? 'Über dieses Organ' : 'About this organ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          children: [
                            if (widget.latinName.isNotEmpty)
                              Text(
                                widget.latinName,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              widget.description,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
