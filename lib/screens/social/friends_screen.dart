import '../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n_extension.dart';
import '../../services/social/social_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home_edge_swipe_back.dart';
import '../../widgets/shared_live_runs_map.dart';
import 'friends_connect_screen.dart';
import 'inbox_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    SocialService.instance.refreshFriendsHubNow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HomeEdgeSwipeBack(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          leadingWidth: 44,
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.friends_hubTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              tooltip: l10n.social_connectTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FriendsConnectScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
            IconButton(
              tooltip: l10n.social_inboxTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const InboxScreen()),
              ),
              icon: const Icon(Icons.inbox_outlined),
            ),
          ],
        ),
        body: const _MonthlyChallengeTab(),
      ),
    );
  }
}

class _MonthlyChallengeTab extends StatelessWidget {
  const _MonthlyChallengeTab();

  Future<void> _editCount(BuildContext context, int currentCount) async {
    final next = await showDialog<int>(
      context: context,
      builder: (_) => _EditChallengeCountDialog(initialCount: currentCount),
    );
    if (next == null) return;
    await SocialService.instance.updateMonthlyPushUpCount(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final materialL10n = MaterialLocalizations.of(context);
    final month = materialL10n.formatMonthYear(DateTime.now());

    return ValueListenableBuilder<int>(
      valueListenable: SocialService.instance.listenable,
      builder: (context, _, _) {
        final service = SocialService.instance;
        final ownCount = service.monthlyPushUpCount;
        final goal = SocialService.monthlyPushUpGoal;
        final friends = service.friendMonthlyChallengeProgress;
        final leaderboard =
            <_ChallengeLeaderboardEntry>[
              _ChallengeLeaderboardEntry(
                uid: 'self',
                displayName: l10n.friends_you,
                count: ownCount,
                isCurrentUser: true,
              ),
              ...friends.map(
                (entry) => _ChallengeLeaderboardEntry(
                  uid: entry.uid,
                  displayName: entry.displayName,
                  count: entry.count,
                  isCurrentUser: false,
                ),
              ),
            ]..sort((a, b) {
              final countOrder = b.count.compareTo(a.count);
              if (countOrder != 0) return countOrder;
              if (a.isCurrentUser) return -1;
              if (b.isCurrentUser) return 1;
              return a.displayName.compareTo(b.displayName);
            });

        return RefreshIndicator(
          onRefresh: service.refreshFriendsHubNow,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              if (service.friendRequests.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_add_alt_1),
                    title: Text(
                      Localizations.localeOf(context).languageCode == 'de'
                          ? '${service.friendRequests.length} Freundschaftsanfragen'
                          : '${service.friendRequests.length} friend requests',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FriendsConnectScreen(),
                      ),
                    ),
                  ),
                ),
              if (!service.cloudEnabled) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    l10n.social_cloudSetupHint,
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                month.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accentText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.friends_challengeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.friends_goal}: ${materialL10n.formatDecimal(goal)} '
                '${l10n.friends_pushUps}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              _ChallengeCountCard(
                count: ownCount,
                goal: goal,
                countLabel: materialL10n.formatDecimal(ownCount),
                pushUpsLabel: l10n.friends_pushUps,
                editLabel: l10n.friends_tapToEdit,
                goalReachedLabel: l10n.friends_goalReached,
                onTap: () => _editCount(context, ownCount),
              ),
              const SizedBox(height: 26),
              Text(
                l10n.friends_leaderboard,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...leaderboard.indexed.map(
                (ranked) => _LeaderboardTile(
                  rank: ranked.$1 + 1,
                  entry: ranked.$2,
                  countLabel: materialL10n.formatDecimal(ranked.$2.count),
                  pushUpsLabel: l10n.friends_pushUps,
                ),
              ),
              if (friends.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.friends_noFriendsHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EditChallengeCountDialog extends StatefulWidget {
  const _EditChallengeCountDialog({required this.initialCount});

  final int initialCount;

  @override
  State<_EditChallengeCountDialog> createState() =>
      _EditChallengeCountDialogState();
}

class _EditChallengeCountDialogState extends State<_EditChallengeCountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialCount}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(int.tryParse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(l10n.friends_editCountTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.friends_editCountHint,
          suffixText: l10n.friends_pushUps,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.friends_save)),
      ],
    );
  }
}

class _ChallengeCountCard extends StatelessWidget {
  const _ChallengeCountCard({
    required this.count,
    required this.goal,
    required this.countLabel,
    required this.pushUpsLabel,
    required this.editLabel,
    required this.goalReachedLabel,
    required this.onTap,
  });

  final int count;
  final int goal;
  final String countLabel;
  final String pushUpsLabel;
  final String editLabel;
  final String goalReachedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (count / goal).clamp(0.0, 1.0);
    final reached = count >= goal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                countLabel,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 52,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pushUpsLabel,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.stroke,
                  color: reached ? const Color(0xFF43B86B) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reached ? goalReachedLabel : editLabel,
                style: TextStyle(
                  color: reached ? const Color(0xFF43B86B) : AppColors.accentText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeLeaderboardEntry {
  const _ChallengeLeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.count,
    required this.isCurrentUser,
  });

  final String uid;
  final String displayName;
  final int count;
  final bool isCurrentUser;
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.countLabel,
    required this.pushUpsLabel,
  });

  final int rank;
  final _ChallengeLeaderboardEntry entry;
  final String countLabel;
  final String pushUpsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: entry.isCurrentUser
                ? AppColors.primary
                : friendAvatarColor(entry.uid),
            child: Text(
              entry.displayName.isEmpty
                  ? '?'
                  : entry.displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: entry.isCurrentUser
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$countLabel $pushUpsLabel',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
