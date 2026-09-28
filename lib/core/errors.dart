import 'package:flutter/material.dart';
import 'package:homeslot_client/homeslot_client.dart';

import 'client.dart';
import 'l10n.dart';

/// A message the user can understand for any error (SRS 4.7). Booking and
/// app errors already carry text in the user's language from the server.
String errorText(BuildContext context, Object error) {
  final s = context.s;
  if (error is BookingException) return error.message;
  if (error is AppException) return error.message;
  if (isConnectionError(error)) return s.errorNetwork;
  return s.errorGeneric;
}

void showError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(errorText(context, error)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
}

void showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
