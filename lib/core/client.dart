import 'dart:async';
import 'dart:io';

import 'package:homeslot_client/homeslot_client.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'config.dart';

/// The Serverpod client used by the whole app. The app never talks to the
/// database directly (SRS 3.3, 4.1).
late final Client client;

/// The server address in use (shown in settings).
String serverUrl = '';

Future<void> initializeClient() async {
  serverUrl = await getServerUrl();
  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();
  // Restore the saved session before the first frame so a signed-in user
  // does not see the sign-in screen flash. Capped so an offline start
  // does not hang.
  try {
    await client.auth.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Continue signed out; the session manager keeps trying.
  }
  if (AppConfig.googleEnabled) {
    unawaited(client.auth.initializeGoogleSignIn());
  }
}

/// Whether [error] means the server could not be reached (offline mode).
bool isConnectionError(Object error) =>
    error is ServerpodClientNetworkException ||
    error is ServerpodClientUnknownException ||
    error is SocketException ||
    error is TimeoutException ||
    error is http.ClientException ||
    error is WebSocketException;
