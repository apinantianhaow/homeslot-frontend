import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Menu of the remaining screens. Owner tools are only listed for owners;
/// the server checks the role again on every request (SRS 4.1).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final me = ref.watch(meProvider).value;
    final isOwner = ref.watch(isOwnerProvider);
    final pending = ref.watch(pendingApprovalsProvider).value?.length ?? 0;
    final unread = ref.watch(unreadCountProvider);

    Widget badge(int n, IconData icon) =>
        Badge(isLabelVisible: n > 0, label: Text('$n'), child: Icon(icon));

    return Scaffold(
      appBar: AppBar(title: Text(s.more)),
      body: ListView(
        children: [
          if (me != null)
            ListTile(
              leading: MemberAvatar(
                name: me.user.displayName,
                color: me.user.color,
                imageUrl: me.user.avatarUrl,
                radius: 24,
              ),
              title: Text(me.user.displayName),
              subtitle: Text(
                '${me.household?.name ?? ''} · ${me.role == null ? '' : s.role(me.role!)}',
              ),
              onTap: () => context.push('/settings'),
            ),
          const Divider(),
          ListTile(
            leading: badge(unread, Icons.notifications_outlined),
            title: Text(s.notifications),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(s.members),
            onTap: () => context.push('/members'),
          ),
          if (isOwner) ...[
            ListTile(
              leading: badge(pending, Icons.pending_actions),
              title: Text(s.approvals),
              onTap: () => context.push('/approvals'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room_outlined),
              title: Text(s.manageRooms),
              onTap: () => context.push('/rooms'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(s.stats),
              onTap: () => context.push('/stats'),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(s.settings),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}
