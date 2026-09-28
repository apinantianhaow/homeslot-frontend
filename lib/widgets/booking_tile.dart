import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/colors.dart';
import '../core/l10n.dart';
import '../state/session.dart';
import 'common.dart';

/// A booking in a list: color bar of the booker, room, time and status.
class BookingTile extends ConsumerWidget {
  const BookingTile({
    super.key,
    required this.view,
    this.showUser = false,
    this.trailing,
    this.onTap,
  });

  final BookingView view;
  final bool showUser;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(houseTimeProvider);
    final s = context.s;
    final b = view.booking;
    final theme = Theme.of(context);
    final subtitle = [
      time.range(b.startAt, b.endAt),
      if (showUser) s.bookedBy(view.userName),
      if (b.purpose != null) b.purpose!,
      if (b.rejectReason != null) s.reasonLabel(b.rejectReason!),
      if (b.cancelReason != null && b.status == BookingStatus.cancelled)
        s.reasonLabel(b.cancelReason!),
    ].join('\n');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: hexColor(view.userColor)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              view.roomName,
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(b.status),
                          if (b.seriesId != null) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: s.recurring,
                              child: Icon(
                                Icons.repeat,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              if (trailing != null)
                Align(alignment: Alignment.center, child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}
