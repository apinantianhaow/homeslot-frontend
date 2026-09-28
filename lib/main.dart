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
  HouseTime.init();
  await initializeDateFormatting();
  await initializeClient();
  await PushService.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Errors are shown with a retry button instead of silent retries.
      retry: (_, _) => null,
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const HomeSlotApp(),
    ),
  );
}
