import '../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/social_models.dart';
import '../../services/social/social_service.dart';
import '../../theme/app_colors.dart';

class FriendsConnectScreen extends StatefulWidget {
  const FriendsConnectScreen({super.key});

  @override
  State<FriendsConnectScreen> createState() => _FriendsConnectScreenState();
}

class _FriendsConnectScreenState extends State<FriendsConnectScreen> {
  final _codeController = TextEditingController();
  String? _errorKey;
  bool _busy = false;

  String t(String de, String en) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;

  @override
  void initState() {
    super.initState();
    SocialService.instance.refreshFriendsHubNow();
  }

  Future<void> _action(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.social_errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(
      ClipboardData(text: SocialService.instance.friendCode),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.social_codeCopied)));
  }

  Future<void> _shareInvite() async {
    final l10n = context.l10n;
    await Share.share(
      l10n.social_inviteShareText(
        SocialService.instance.inviteLink,
        SocialService.instance.friendCode,
      ),
    );
  }

  Future<void> _addFriend() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    String? result;
    try {
      result = await SocialService.instance.addFriendByCode(code);
    } catch (_) {
      result = 'network';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Anfrage gesendet. Dein Freund muss sie bestätigen.',
              'Request sent. Your friend needs to accept it.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _errorKey = result);
  }

  Future<void> _removeFriend(FriendConnection friend) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          l10n.social_removeFriendTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.social_removeFriendBody(friend.displayName),
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _action(() => SocialService.instance.removeFriend(friend.uid));
    }
  }

  String _errorText(AppLocalizations l10n) {
    switch (_errorKey) {
      case 'invalid':
        return l10n.social_errorInvalidCode;
      case 'self':
        return l10n.social_errorSelfFriend;
      case 'not_found':
        return l10n.social_errorFriendNotFound;
      case 'already':
        return l10n.social_errorAlreadyFriends;
      case 'cloud_disabled':
        return l10n.social_errorCloudDisabled;
      default:
        return l10n.social_errorGeneric;
    }
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
          l10n.social_connectTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: SocialService.instance.listenable,
        builder: (context, _, _) {
          final friends = SocialService.instance.friends;
          final cloud = SocialService.instance.cloudEnabled;
          return RefreshIndicator(
            onRefresh: SocialService.instance.refreshFriendsHubNow,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (!cloud)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Text(
                      l10n.social_cloudSetupHint,
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                  ),
                _SectionCard(
                  title: l10n.social_yourIdTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        SocialService.instance.friendCode,
                        style: TextStyle(
                          color: AppColors.accentText,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'RobotoMono',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyCode,
                              icon: const Icon(Icons.copy, size: 18),
                              label: Text(l10n.social_copyCode),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _shareInvite,
                              icon: const Icon(Icons.share, size: 18),
                              label: Text(l10n.social_shareInvite),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n.social_addFriendTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: l10n.social_addFriendHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (_errorKey != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorText(l10n),
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy ? null : _addFriend,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                t(
                                  'Freundschaft anfragen',
                                  'Send friend request',
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (SocialService.instance.friendRequests.isNotEmpty) ...[
                  Text(
                    t('Freundschaftsanfragen', 'Friend requests'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    t(
                      'Nach dem Bestätigen könnt ihr geteilte Läufe verfolgen und Inhalte austauschen.',
                      'After accepting, you can follow shared runs and exchange content.',
                    ),
                  ),
                  for (final request in SocialService.instance.friendRequests)
                    Card(
                      child: ListTile(
                        title: Text(request.displayName),
                        subtitle: Text(request.friendCode),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: t('Ablehnen', 'Decline'),
                              onPressed: _busy
                                  ? null
                                  : () => _action(
                                      () => SocialService.instance
                                          .rejectFriendRequest(request.uid),
                                    ),
                              icon: const Icon(Icons.close),
                            ),
                            IconButton(
                              tooltip: t('Bestätigen', 'Accept'),
                              onPressed: _busy
                                  ? null
                                  : () => _action(
                                      () => SocialService.instance
                                          .acceptFriendRequest(request),
                                    ),
                              icon: const Icon(Icons.check),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.social_friendsListTitle(friends.length),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (friends.isEmpty)
                  Text(
                    l10n.social_noFriendsYet,
                    style: TextStyle(color: AppColors.textMuted),
                  )
                else
                  ...friends.map(
                    (friend) => _FriendTile(
                      friend: friend,
                      onRemove: () => _removeFriend(friend),
                      onNotifyChanged: (value) => _action(
                        () => SocialService.instance.setNotifyOnRunStart(
                          friend.uid,
                          value,
                        ),
                      ),
                      onThumbsUp: SocialService.instance.cloudEnabled
                          ? () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await SocialService.instance.sendThumbsUp(
                                  friend.uid,
                                );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.social_thumbsUpSent),
                                  ),
                                );
                              } catch (_) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.social_errorGeneric),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.onRemove,
    required this.onNotifyChanged,
    this.onThumbsUp,
  });

  final FriendConnection friend;
  final VoidCallback onRemove;
  final ValueChanged<bool> onNotifyChanged;
  final VoidCallback? onThumbsUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              friend.displayName.isNotEmpty
                  ? friend.displayName.characters.first.toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.accentText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  friend.friendCode,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    l10n.social_notifyRunStart,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  value: friend.notifyOnRunStart,
                  onChanged: onNotifyChanged,
                ),
              ],
            ),
          ),
          if (onThumbsUp != null)
            IconButton(
              tooltip: l10n.social_sendThumbsUp,
              onPressed: onThumbsUp,
              icon: const Text('👍', style: TextStyle(fontSize: 20)),
            ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.person_remove_outlined,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
