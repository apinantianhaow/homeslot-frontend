import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n.dart';
import '../state/data.dart';
import '../widgets/common.dart';

/// Screen 8 (owners): list of rooms to add, edit or delete (SRS 2.2).
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final rooms = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.manageRooms)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (ensureOnline(context, ref)) context.push('/rooms/edit');
        },
        icon: const Icon(Icons.add),
        label: Text(s.newRoom),
      ),
      body: AsyncView(
        value: rooms,
        onRetry: () => ref.invalidate(roomsProvider),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.meeting_room_outlined, text: s.noRooms)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = list[i];
                  final r = d.room;
                  return Card(
                    child: ListTile(
                      leading: RoomAvatar(room: r, size: 44),
                      title: Text(r.name),
                      subtitle: Text(
                        [
                          s.roomTypeName(r.type),
                          s.roomRules(
                            r.slotMinutes,
                            s.duration(r.minMinutes),
                            s.duration(r.maxMinutes),
                            r.advanceDays,
                          ),
                          if (r.requiresApproval) s.requiresApproval,
                          if (d.closures.isNotEmpty) s.closures,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (ensureOnline(context, ref)) {
                          context.push('/rooms/edit', extra: d);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
