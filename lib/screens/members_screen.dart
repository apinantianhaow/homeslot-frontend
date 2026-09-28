import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/client.dart';
import '../core/config.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Screen 9: members and roles; owners invite with a 6-digit code or QR
/// code and manage roles (SRS 2.1.4, 2.1.6).
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  Future<void> _createInvite(BuildContext context, WidgetRef ref) async {
    if (!ensureOnline(context, ref)) return;
    try {
      final invite = await client.household.createInvite();
      ref.invalidate(invitesProvider);
      if (context.mounted) await _showInvite(context, ref, invite);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  static Future<void> _showInvite(
    BuildContext context,
    WidgetRef ref,
    Invitation invite,
  ) {
    final s = context.s;
    final time = ref.read(houseTimeProvider);
    final link = AppConfig.inviteLink(invite.code);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.invite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: link, size: 200),
            ),
            const SizedBox(height: 12),
            SelectableText(
              invite.code,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              s.inviteExpires(
                '${time.dayLabel(invite.expiresAt)} ${time.hm(invite.expiresAt)}',
              ),
            ),
            const SizedBox(height: 8),
            Text(s.inviteHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: s.inviteShareText(invite.code, link)),
            ),
            icon: const Icon(Icons.share),
            label: Text(s.share),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  Future<void> _memberAction(
    BuildContext context,
    WidgetRef ref,
    MemberInfo member,
    String action,
  ) async {
    if (!ensureOnline(context, ref)) return;
    final s = context.s;
    try {
      switch (action) {
        case 'owner':
          await client.household.changeRole(member.userId, MemberRole.owner);
        case 'member':
          await client.household.changeRole(member.userId, MemberRole.member);
        case 'remove':
          if (!await confirmDialog(
            context,
            message: s.removeMemberConfirm(member.displayName),
            confirmLabel: s.removeMember,
            destructive: true,
          )) {
            return;
          }
          await client.household.removeMember(member.userId);
      }
      ref.invalidate(membersProvider);
      ref.invalidate(meProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final isOwner = ref.watch(isOwnerProvider);
    final myId = ref.watch(myUserIdProvider);
    final time = ref.watch(houseTimeProvider);
    final members = ref.watch(membersProvider);
    final invites = ref.watch(invitesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.members)),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _createInvite(context, ref),
              icon: const Icon(Icons.qr_code_2),
              label: Text(s.createInvite),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(membersProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            AsyncView(
              value: members,
              onRetry: () => ref.invalidate(membersProvider),
              data: (list) => Column(
                children: [
                  for (final m in list)
                    ListTile(
                      leading: MemberAvatar(
                        name: m.displayName,
                        color: m.color,
                        imageUrl: m.avatarUrl,
                      ),
                      title: Text(
                        m.userId == myId
                            ? '${m.displayName} ${s.you}'
                            : m.displayName,
                      ),
                      subtitle: Text([s.role(m.role), ?m.email].join(' · ')),
                      trailing: !isOwner || m.userId == myId
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (a) =>
                                  _memberAction(context, ref, m, a),
                              itemBuilder: (_) => [
                                if (m.role == MemberRole.member)
                                  PopupMenuItem(
                                    value: 'owner',
                                    child: Text(s.makeOwner),
                                  )
                                else
                                  PopupMenuItem(
                                    value: 'member',
                                    child: Text(s.makeMember),
                                  ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(s.removeMember),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
            if (isOwner) ...[
              SectionHeader(s.activeInvites),
              AsyncView(
                value: invites,
                onRetry: () => ref.invalidate(invitesProvider),
                data: (list) => Column(
                  children: [
                    for (final invite in list)
                      ListTile(
                        leading: const Icon(Icons.qr_code),
                        title: Text(
                          invite.code,
                          style: const TextStyle(letterSpacing: 4),
                        ),
                        subtitle: Text(
                          s.inviteExpires(
                            '${time.dayLabel(invite.expiresAt)} ${time.hm(invite.expiresAt)}',
                          ),
                        ),
                        onTap: () => _showInvite(context, ref, invite),
                        trailing: TextButton(
                          onPressed: () async {
                            try {
                              await client.household.revokeInvite(invite.id!);
                              ref.invalidate(invitesProvider);
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
                          child: Text(s.revoke),
                        ),
                      ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(s.inviteHint),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
