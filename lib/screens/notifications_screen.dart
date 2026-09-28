import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Screen 11 (part 1): notification history of the last 30 days (SRS 2.5.4).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static IconData icon(NotificationType type) => switch (type) {
    NotificationType.bookingReminder => Icons.alarm,
    NotificationType.approvalRequested => Icons.pending_actions,
    NotificationType.bookingApproved => Icons.check_circle_outline,
    NotificationType.bookingRejected => Icons.block,
    NotificationType.bookingExpired => Icons.timer_off_outlined,
    NotificationType.bookingCancelledByOther => Icons.event_busy,
    NotificationType.roomClosed => Icons.construction,
    NotificationType.memberRemoved => Icons.person_remove_outlined,
    NotificationType.roleChanged => Icons.admin_panel_settings_outlined,
    NotificationType.general => Icons.notifications_outlined,
  };

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (n.readAt == null) {
      try {
        await client.notification.markRead(n.id!);
        ref.invalidate(notificationsProvider);
      } catch (_) {
        // Reading still works offline; the mark is sent next time.
      }
    }
    if (!context.mounted) return;
    switch (n.type) {
      case NotificationType.approvalRequested:
        context.push('/approvals');
      case NotificationType.memberRemoved:
      case NotificationType.roleChanged:
      case NotificationType.general:
        break;
      default:
        context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final time = ref.watch(houseTimeProvider);
    final list = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await client.notification.markAllRead();
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: Text(s.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: AsyncView(
          value: list,
          onRetry: () => ref.invalidate(notificationsProvider),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.notifications_none,
                      text: s.noNotifications,
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final unread = n.readAt == null;
                    return ListTile(
                      leading: Icon(icon(n.type)),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Text(
                        '${n.body}\n${time.dayLabel(n.createdAt)} ${time.hm(n.createdAt)}',
                      ),
                      isThreeLine: true,
                      trailing: unread
                          ? Icon(
                              Icons.circle,
                              size: 10,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => _open(context, ref, n),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
