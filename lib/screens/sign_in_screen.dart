import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../core/client.dart';
import '../core/config.dart';
import '../core/errors.dart';
import '../core/l10n.dart';

/// Screen 1: sign in or register with email and password, or Google
/// (SRS 2.1.1, 2.1.2). Password reset is part of the email flow.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Icon(
                    Icons.meeting_room_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(s.appName, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    s.signInTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.signInSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SignInWidget(
                    client: client,
                    disableGoogleSignInWidget: !AppConfig.googleEnabled,
                    onError: (error) => showError(context, error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
