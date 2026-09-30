import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../core/client.dart';
import '../core/time.dart';
import '../data/cached.dart';
import 'push.dart';
import 'settings.dart';

/// Whether a user is signed in (Serverpod auth session).
final signedInProvider = NotifierProvider<SignedInNotifier, bool>(
  SignedInNotifier.new,
);

class SignedInNotifier extends Notifier<bool> {
  @override
  bool build() {
    void listener() => state = client.auth.isAuthenticated;
    client.auth.authInfoListenable.addListener(listener);
    ref.onDispose(
      () => client.auth.authInfoListenable.removeListener(listener),
    );
    return client.auth.isAuthenticated;
  }
}

/// The signed-in user with their household and role.
final meProvider = AsyncNotifierProvider<MeNotifier, MeInfo?>(MeNotifier.new);

class MeNotifier extends AsyncNotifier<MeInfo?> {
  @override
  Future<MeInfo?> build() async {
    if (!ref.watch(signedInProvider)) return null;
    return cachedFetch(ref, 'me', () => client.account.me());
  }

  void set(MeInfo me) => state = AsyncData(me);

  void updateUser(AppUser user) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(user: user));
  }
}

final householdIdProvider = Provider<int?>(
  (ref) => ref.watch(meProvider).value?.household?.id,
);

final isOwnerProvider = Provider<bool>(
  (ref) => ref.watch(meProvider).value?.role == MemberRole.owner,
);

final myUserIdProvider = Provider<int?>(
  (ref) => ref.watch(meProvider).value?.user.id,
);

/// Formatting and conversion in the household time zone (SRS 4.3).
///
/// Depends only on the zone and the language: every screen that shows a
/// time watches this, so it must not change on each profile reload.
final houseTimeProvider = Provider<HouseTime>((ref) {
  final zone =
      ref.watch(meProvider.select((me) => me.value?.household?.timezone)) ??
      'Asia/Bangkok';
  final locale = ref.watch(settingsProvider.select((s) => s.localeCode));
  return HouseTime(zone, locale);
});

/// An invite code from a deep link, kept until the user has signed in.
final pendingInviteProvider = NotifierProvider<PendingInvite, String?>(
  PendingInvite.new,
);

class PendingInvite extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

/// Signs out on this device: stops push, clears the offline cache and
/// forgets the session.
Future<void> signOut(WidgetRef ref) async {
  await PushService.unregister();
  await ref.read(cacheDbProvider).clear();
  try {
    await client.auth.signOutDevice();
  } catch (_) {
    // The session may already be revoked (e.g. after deleting the account).
  }
}
