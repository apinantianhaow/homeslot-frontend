import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Shown while loading the user, or when it cannot be loaded.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      body: SafeArea(
        child: me.hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ErrorView(
                    error: me.error!,
                    onRetry: () => ref.invalidate(meProvider),
                  ),
                  TextButton(
                    onPressed: () => signOut(ref),
                    child: Text(context.s.signOut),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
