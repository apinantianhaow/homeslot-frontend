import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import '../core/colors.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../core/time.dart';
import '../core/upload.dart';
import '../data/cached.dart';
import '../state/push.dart';
import '../state/session.dart';
import '../state/settings.dart';
import '../widgets/common.dart';

/// Screen 11 (part 2): profile, language, theme, reminder time, household
/// and account (SRS 2.1.7, 2.1.8, 2.5.1, 4.7, PDPA).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  String _color = memberColors.first;
  String? _avatarUrl;
  double? _reminder;
  bool _loaded = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _load(AppUser user) {
    if (_loaded) return;
    _loaded = true;
    _name.text = user.displayName;
    _color = user.color;
    _avatarUrl = user.avatarUrl;
  }

  Future<void> _saveProfile() async {
    if (!ensureOnline(context, ref)) return;
    try {
      final user = await client.account.updateProfile(
        _name.text,
        _color,
        _avatarUrl,
      );
      ref.read(meProvider.notifier).updateUser(user);
      if (mounted) showMessage(context, context.s.saved);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pickAvatar() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(kind: 'avatar');
      if (url != null) setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveReminder(
    AppUser user, {
    bool? enabled,
    int? minutes,
  }) async {
    try {
      final saved = await client.account.updateSettings(
        enabled ?? user.reminderEnabled,
        minutes ?? user.reminderMinutes,
        ref.read(settingsProvider).localeCode,
      );
      ref.read(meProvider.notifier).updateUser(saved);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _setLanguage(AppUser user, String code) async {
    await ref.read(settingsProvider.notifier).setLocale(code);
    try {
      final saved = await client.account.updateSettings(
        user.reminderEnabled,
        user.reminderMinutes,
        code,
      );
      ref.read(meProvider.notifier).updateUser(saved);
    } catch (_) {
      // Synced again when the app starts.
    }
  }

  Future<void> _editHousehold(Household household) async {
    final s = context.s;
    final name = await textDialog(
      context,
      title: s.editHousehold,
      label: s.householdName,
      initial: household.name,
      required: true,
    );
    if (name == null) return;
    try {
      await client.household.update(name, household.timezone);
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _leave() async {
    final s = context.s;
    if (!await confirmDialog(
      context,
      message: s.leaveConfirm,
      confirmLabel: s.leaveHousehold,
      destructive: true,
    )) {
      return;
    }
    try {
      await client.household.leave();
      await ref.read(cacheDbProvider).clear();
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _signOut() => signOut(ref);

  Future<void> _deleteAccount() async {
    final s = context.s;
    if (!await confirmDialog(
      context,
      title: s.deleteAccount,
      message: s.deleteAccountConfirm,
      confirmLabel: s.deleteAccount,
      destructive: true,
    )) {
      return;
    }
    try {
      await PushService.unregister();
      await client.account.deleteAccount();
      await signOut(ref);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final me = ref.watch(meProvider).value;
    final settings = ref.watch(settingsProvider);
    final isOwner = ref.watch(isOwnerProvider);
    if (me == null) return const Scaffold();
    final user = me.user;
    _load(user);
    final reminder = _reminder ?? user.reminderMinutes.toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(s.profile),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      MemberAvatar(
                        name: _name.text,
                        color: _color,
                        imageUrl: _avatarUrl,
                        radius: 32,
                      ),
                      const CircleAvatar(
                        radius: 11,
                        child: Icon(Icons.edit, size: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 40,
                    decoration: InputDecoration(labelText: s.displayName),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(s.myColor),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in memberColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: hexColor(c),
                      child: _color.toUpperCase() == c
                          ? Icon(Icons.check, color: onColor(hexColor(c)))
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonal(
              onPressed: _saveProfile,
              child: Text(s.save),
            ),
          ),
          SectionHeader(s.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'th', label: Text('ไทย')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.localeCode},
              onSelectionChanged: (v) => _setLanguage(user, v.first),
            ),
          ),
          SectionHeader(s.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(s.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(s.themeLight),
                ),
                ButtonSegment(value: ThemeMode.dark, label: Text(s.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) =>
                  ref.read(settingsProvider.notifier).setThemeMode(v.first),
            ),
          ),
          SectionHeader(s.reminders),
          SwitchListTile(
            title: Text(s.reminders),
            subtitle: Text(s.reminderMinutes(reminder.round())),
            value: user.reminderEnabled,
            onChanged: (v) => _saveReminder(user, enabled: v),
          ),
          Slider(
            value: reminder,
            min: 5,
            max: 60,
            divisions: 11,
            label: s.reminderMinutes(reminder.round()),
            onChanged: user.reminderEnabled
                ? (v) => setState(() => _reminder = v)
                : null,
            onChangeEnd: (v) => _saveReminder(user, minutes: v.round()),
          ),
          if (!PushService.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.pushDisabled,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (me.household != null) ...[
            SectionHeader(s.household),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(me.household!.name),
              subtitle: Text('${s.timeZone}: ${me.household!.timezone}'),
              trailing: isOwner ? const Icon(Icons.edit_outlined) : null,
              onTap: isOwner ? () => _editHousehold(me.household!) : null,
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: Text(s.leaveHousehold),
              onTap: _leave,
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(s.signOut),
            onTap: _signOut,
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              s.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _deleteAccount,
          ),
          SectionHeader(s.about),
          ListTile(
            title: const Text('HomeSlot 1.0.0'),
            subtitle: Text('${s.server}: $serverUrl'),
          ),
          ListTile(
            title: Text(s.timeZone),
            subtitle: Text(ref.watch(houseTimeProvider).location.name),
            trailing: Text(
              HouseTime.minuteLabel(
                ref.watch(houseTimeProvider).minuteOfDay(DateTime.now()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
