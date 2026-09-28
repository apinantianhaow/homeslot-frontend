import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../state/data.dart';
import '../widgets/booking_tile.dart';
import '../widgets/common.dart';

/// Screen 7 (owners): pending requests with approve and reject (SRS 2.4).
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    BookingView view, {
    required bool approve,
  }) async {
    if (!ensureOnline(context, ref)) return;
    final s = context.s;
    var scope = EditScope.single;
    if (view.booking.seriesId != null) {
      final whole = await confirmDialog(
        context,
        message: s.applyToSeries,
        confirmLabel: s.scopeSeries,
      );
      scope = whole ? EditScope.series : EditScope.single;
    }
    String? reason;
    if (!approve) {
      if (!context.mounted) return;
      reason = await textDialog(
        context,
        title: s.reject,
        label: s.rejectReason,
      );
      if (reason == null) return;
    }
    try {
      if (approve) {
        await client.booking.approve(view.booking.id!, scope);
      } else {
        await client.booking.reject(view.booking.id!, reason, scope);
      }
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(calendarProvider);
      ref.invalidate(roomStatusProvider);
      if (context.mounted) {
        showMessage(context, approve ? s.approved : s.rejected);
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final pending = ref.watch(pendingApprovalsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.approvals)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingApprovalsProvider.future),
        child: AsyncView(
          value: pending,
          onRetry: () => ref.invalidate(pendingApprovalsProvider),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    EmptyState(icon: Icons.task_alt, text: s.noApprovals),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final view = list[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BookingTile(view: view, showUser: true),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _decide(context, ref, view, approve: false),
                              icon: const Icon(Icons.close),
                              label: Text(s.reject),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () =>
                                  _decide(context, ref, view, approve: true),
                              icon: const Icon(Icons.check),
                              label: Text(s.approve),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
