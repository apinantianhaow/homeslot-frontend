import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/client.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../core/time.dart';
import '../state/session.dart';

/// Screen 2: create a household (becoming its owner) or join one with a
/// 6-digit invite code or QR code (SRS 2.1.3, 2.1.5).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  String _zone = 'Asia/Bangkok';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(pendingInviteProvider);
    if (pending != null) _code.text = pending;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() => _run(() async {
    final me = await client.household.create(_name.text, _zone);
    ref.read(meProvider.notifier).set(me);
  });

  Future<void> _join() => _run(() async {
    final me = await client.household.join(_code.text);
    ref.read(pendingInviteProvider.notifier).set(null);
    ref.read(meProvider.notifier).set(me);
  });

  Future<void> _scan() async {
    final code = await context.push<String>('/scan');
    if (code != null && mounted) {
      _code.text = code;
      await _join();
    }
  }

  @override
  Widget build(BuildContext context) {
    // An invite link opened while this screen is showing fills in the code.
    ref.listen<String?>(pendingInviteProvider, (_, code) {
      if (code != null) _code.text = code;
    });
    final s = context.s;
    final theme = Theme.of(context);
    final zones = {..._zoneOptions(), _zone}.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        actions: [
          IconButton(
            tooltip: s.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(ref),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.welcomeTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(s.welcomeSubtitle),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.joinHousehold, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(labelText: s.inviteCode),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scan,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(s.scanQr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _join,
                            child: Text(s.join),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.createHousehold, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      maxLength: 60,
                      decoration: InputDecoration(labelText: s.householdName),
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _zone,
                      decoration: InputDecoration(labelText: s.timeZone),
                      items: [
                        for (final z in zones)
                          DropdownMenuItem(value: z, child: Text(z)),
                      ],
                      onChanged: (z) => setState(() => _zone = z ?? _zone),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _create,
                      child: Text(s.create),
                    ),
                  ],
                ),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _zoneOptions() => commonTimeZones;
}
