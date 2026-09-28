import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeslot_client/homeslot_client.dart';

import 'core/l10n.dart';
import 'screens/approvals_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/members_screen.dart';
import 'screens/more_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/room_edit_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/data.dart';
import 'state/session.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Routes for the 11 screens of SRS 3.1. Signed-out users go to sign-in,
/// users without a household go to create/join, everyone else to the tabs.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(signedInProvider, (_, _) => refresh.value++);
  ref.listen(meProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Invite deep link: homeslot://app/join?code=123456
      if (location == '/join') {
        final code = state.uri.queryParameters['code'];
        if (code != null) ref.read(pendingInviteProvider.notifier).set(code);
      }

      if (!ref.read(signedInProvider)) {
        return location == '/sign-in' ? null : '/sign-in';
      }
      // A signed-in user whose profile is not loaded yet (or failed to load)
      // waits on the splash screen, which also shows errors with a retry.
      final me = ref.read(meProvider).value;
      if (me == null) return location == '/splash' ? null : '/splash';
      if (me.household == null) {
        const setup = {'/welcome', '/scan'};
        return setup.contains(location) ? null : '/welcome';
      }
      const entry = {'/sign-in', '/splash', '/welcome', '/join', '/scan'};
      return entry.contains(location) ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/join', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabsScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, _) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (_, _) => const MyBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/book',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            BookingFormScreen(args: state.extra as BookingFormArgs?),
      ),
      GoRoute(
        path: '/approvals',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ApprovalsScreen(),
      ),
      GoRoute(
        path: '/rooms',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RoomsScreen(),
      ),
      GoRoute(
        path: '/rooms/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            RoomEditScreen(detail: state.extra as RoomDetail?),
      ),
      GoRoute(
        path: '/members',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MembersScreen(),
      ),
      GoRoute(
        path: '/stats',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StatsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _TabsScaffold extends ConsumerWidget {
  const _TabsScaffold({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final pending = ref.watch(pendingApprovalsProvider).value?.length ?? 0;
    final unread = ref.watch(unreadCountProvider);
    final moreBadge = pending + unread;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: s.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: s.navBookings,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: moreBadge > 0,
              label: Text('$moreBadge'),
              child: const Icon(Icons.menu),
            ),
            label: s.navMore,
          ),
        ],
      ),
    );
  }
}
