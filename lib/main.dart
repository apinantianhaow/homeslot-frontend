import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/client.dart';
import 'core/time.dart';
import 'state/push.dart';
import 'state/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Independent start-up work runs at the same time, so the first frame
  // waits for the slowest step instead of the sum of all of them.
  final ready = (
    initializeDateFormatting(),
    initializeClient(),
    PushService.init(),
    SharedPreferences.getInstance(),
  ).wait;
  // Decoding the time zone database is CPU work; do it while the platform
  // calls above are in flight.
  HouseTime.init();
  final (_, _, _, prefs) = await ready;

  runApp(
    ProviderScope(
      // Errors are shown with a retry button instead of silent retries.
      retry: (_, _) => null,
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const HomeSlotApp(),
    ),
  );
}
