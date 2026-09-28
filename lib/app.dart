import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';

import 'core/client.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'router.dart';
import 'state/data.dart';
import 'state/push.dart';
import 'state/realtime.dart';
import 'state/session.dart';
import 'state/settings.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class HomeSlotApp extends ConsumerStatefulWidget {
  const HomeSlotApp({super.key});

  @override
  ConsumerState<HomeSlotApp> createState() => _HomeSlotAppState();
}

class _HomeSlotAppState extends ConsumerState<HomeSlotApp> {
  StreamSubscription<Object>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    _pushSubscription = PushService.foregroundMessages.listen((message) {
      ref.invalidate(notificationsProvider);
      final title = message.notification?.title;
      if (title != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(title)),
        );
      }
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    // Keep the real-time connection open while the app runs.
    ref.watch(realtimeProvider);

    // After sign-in: register for push and tell the server which language
    // to use for notifications.
    ref.listen<AsyncValue<MeInfo?>>(meProvider, (previous, next) {
      final me = next.value;
      if (me == null) return;
      if (previous?.value?.user.id != me.user.id) {
        unawaited(PushService.register());
      }
      if (me.user.locale != settings.localeCode) {
        unawaited(_syncLocale(me.user, settings.localeCode));
      }
    });

    return MaterialApp.router(
      title: 'HomeSlot',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: Locale(settings.localeCode),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }

  Future<void> _syncLocale(AppUser user, String locale) async {
    try {
      final saved = await client.account.updateSettings(
        user.reminderEnabled,
        user.reminderMinutes,
        locale,
      );
      ref.read(meProvider.notifier).updateUser(saved);
    } catch (_) {
      // Not critical: retried on the next change.
    }
  }
}
