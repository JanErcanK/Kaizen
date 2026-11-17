import '../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/social_models.dart';
import '../../services/social/social_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/run_share_sheet.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final Set<String> _busy = {};
  @override
  void initState() {
    super.initState();
    SocialService.instance.refreshFriendsHubNow();
  }

  Future<void> _perform(
    InboxMessage message,
    Future<void> Function() action, {
    bool showAdded = false,
  }) async {
    if (!_busy.add(message.id)) return;
    setState(() {});
    try {
      await action();
      if (mounted && showAdded) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.social_inboxAdded)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.social_errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(message.id));
    }
  }

  bool _isShareable(ShareContentType type) => type != ShareContentType.thumbsUp;

  String _messageBody(AppLocalizations l10n, InboxMessage message) {
    switch (message.type) {
      case ShareContentType.runningRoute:
        return l10n.social_inboxRoute(message.fromName);
      case ShareContentType.gymWorkout:
        return l10n.social_inboxGymWorkout(message.fromName);
      case ShareContentType.calisthenicsWorkout:
        return l10n.social_inboxCalisthenicsWorkout(message.fromName);
      case ShareContentType.foodDish:
        return l10n.social_inboxFoodDish(message.fromName);
      case ShareContentType.thumbsUp:
        return l10n.social_inboxThumbsUp(message.fromName);
    }
  }

  String _acceptLabel(AppLocalizations l10n, ShareContentType type) {
    switch (type) {
      case ShareContentType.runningRoute:
        return l10n.social_acceptRoute;
      case ShareContentType.gymWorkout:
      case ShareContentType.calisthenicsWorkout:
        return l10n.social_acceptWorkout;
      case ShareContentType.foodDish:
        return l10n.social_acceptDish;
      case ShareContentType.thumbsUp:
        return l10n.common_ok;
    }
  }

  String? _payloadTitle(InboxMessage message) {
    if (message.type == ShareContentType.thumbsUp) return null;
    final name = message.payload['name']?.toString().trim() ?? '';
    return name.isEmpty ? null : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        title: Text(
          l10n.social_inboxTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: SocialService.instance.listenable,
        builder: (context, _, _) {
          final messages = SocialService.instance.inbox;
          if (messages.isEmpty) {
            return Center(
              child: Text(
                l10n.social_inboxEmpty,
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final message = messages[index];
              final pending = message.isPending;
              final shareable = _isShareable(message.type);
              final title = _payloadTitle(message);

              return Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                decoration: AppColors.surfaceDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (message.type ==
                                  ShareContentType.thumbsUp) ...[
                                const Text(
                                  '👍',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _messageBody(l10n, message),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (title != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                          if (message.type ==
                              ShareContentType.runningRoute) ...[
                            const SizedBox(height: 12),
                            RunSnapshotPreview(route: message.payload),
                          ],
                          if (!pending && shareable) ...[
                            const SizedBox(height: 8),
                            Text(
                              message.status == InboxMessageStatus.accepted
                                  ? l10n.social_inboxAccepted
                                  : l10n.social_inboxRejected,
                              style: TextStyle(
                                color:
                                    message.status ==
                                        InboxMessageStatus.accepted
                                    ? AppColors.accentText
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (pending && shareable) ...[
                            const SizedBox(height: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.actionBackground,
                                foregroundColor: AppColors.onAction,
                              ),
                              onPressed: _busy.contains(message.id)
                                  ? null
                                  : () => _perform(
                                      message,
                                      () => SocialService.instance
                                          .acceptMessage(message),
                                      showAdded: true,
                                    ),
                              child: Text(_acceptLabel(l10n, message.type)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.common_delete,
                      onPressed: _busy.contains(message.id)
                          ? null
                          : () => _perform(
                              message,
                              () => SocialService.instance.deleteInboxMessage(
                                message,
                              ),
                            ),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
