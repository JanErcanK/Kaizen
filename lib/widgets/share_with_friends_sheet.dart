import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/social_models.dart';
import '../services/social/social_service.dart';
import '../theme/app_colors.dart';

Future<void> showShareWithFriendsSheet({
  required BuildContext context,
  required ShareContentType type,
  required Map<String, dynamic> payload,
}) async {
  final l10n = context.l10n;
  final friends = SocialService.instance.friends;
  if (!SocialService.instance.cloudEnabled) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.social_errorCloudDisabled)));
    return;
  }
  if (friends.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.social_noFriendsToShare)));
    return;
  }

  String? sendingUid;
  String? error;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.social_shareWithFriendsTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payload['name']?.toString() ?? '',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ...friends.map(
                    (friend) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName.characters.first
                                    .toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.accentText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        friend.displayName,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        friend.friendCode,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: sendingUid == friend.uid
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send, color: AppColors.primary),
                      onTap: sendingUid != null
                          ? null
                          : () async {
                              setSheetState(() {
                                sendingUid = friend.uid;
                                error = null;
                              });
                              try {
                                await SocialService.instance.shareWithFriend(
                                  friendUid: friend.uid,
                                  type: type,
                                  payload: payload,
                                );
                                if (ctx.mounted && context.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.social_shareSent),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    error = l10n.social_errorGeneric;
                                    sendingUid = null;
                                  });
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
