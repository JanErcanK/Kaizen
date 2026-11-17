import 'package:flutter/material.dart';

import '../../l10n/l10n_extension.dart';
import '../../services/social/social_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared_live_runs_map.dart';
import 'friend_live_run_detail_screen.dart';

class SharedRunsTab extends StatefulWidget {
  const SharedRunsTab({super.key});

  @override
  State<SharedRunsTab> createState() => _SharedRunsTabState();
}

class _SharedRunsTabState extends State<SharedRunsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: SocialService.instance.listenable,
      builder: (context, _, __) {
        final runs = SocialService.instance.friendsLiveRuns;
        final cloud = SocialService.instance.cloudEnabled;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (!cloud)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: AppColors.surfaceDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.social_cloudSetupHint,
                  style: TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
              ),
            Text(
              l10n.sharedRuns_tabHint,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            SharedLiveRunsMap(runs: runs, height: 420),
            if (runs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.sharedRuns_liveCount(runs.length),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...runs.map(
                (run) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: friendAvatarColor(run.uid),
                    child: Text(
                      run.displayName.isNotEmpty
                          ? run.displayName.characters.first.toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    run.displayName,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${run.routeName} · ${formatPaceSecPerKm(run.currentPaceSecPerKm)} /km',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FriendLiveRunDetailScreen(run: run),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
