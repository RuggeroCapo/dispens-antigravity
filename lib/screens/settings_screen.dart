import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../repositories/food_repository.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesServiceProvider);
    final notificationTime = prefs.notificationTime;
    final timeStr =
        '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [

          // ── Notifications ──
          _SectionHeader(label: 'Notifications'),
          _SettingsCard(children: [
            _SettingsRowSwitch(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              value: true, // placeholder – always on if permission granted
              onToggle: (_) async {
                final svc = await ref.read(notificationServiceProvider.future);
                await svc.requestPermissions();
              },
            ),
            const _Divider(),
            _SettingsRowNavigate(
              icon: Icons.schedule_outlined,
              label: 'Daily Notification Time',
              value: timeStr,
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: notificationTime,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (selected != null) {
                  await prefs.setNotificationTime(selected);
                }
              },
            ),
            const _Divider(),
            _SettingsRowNavigate(
              icon: Icons.verified_user_outlined,
              label: 'Permission Status',
              onTap: () async {
                final svc = await ref.read(notificationServiceProvider.future);
                final granted = await svc.requestPermissions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(granted
                        ? '✓ Notifications allowed'
                        : '✗ Permission denied'),
                  ));
                }
              },
              valueWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Appearance ──
          _SectionHeader(label: 'Appearance'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.palette_outlined,
              label: 'Theme',
              value: 'System Default',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // ── Data ──
          _SectionHeader(label: 'Data'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.upload_outlined,
              label: 'Export Data',
              onTap: () async {
                try {
                  final repo =
                      await ref.read(asyncFoodRepositoryProvider.future);
                  final items = await repo.getItems();
                  final json = jsonEncode(items.map((e) => e.toJson()).toList());
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/dispens_backup.json');
                  await file.writeAsString(json);
                  // ignore: deprecated_member_use
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Dispens Backup');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: $e')));
                  }
                }
              },
            ),
            const _Divider(),
            _SettingsRowNavigate(
              icon: Icons.download_outlined,
              label: 'Import Data',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Import coming soon')));
              },
            ),
          ]),
          const SizedBox(height: 24),

          // ── About ──
          _SectionHeader(label: 'About'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.info_outline_rounded,
              label: 'Version',
              value: '1.0.0',
              onTap: () {},
              showChevron: false,
            ),
          ]),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Dispens — Your household food inventory manager',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Shared widgets
// ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          )),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 52),
      child: Divider(height: 1),
    );
  }
}

class _SettingsRowSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onToggle;

  const _SettingsRowSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary)),
          ),
          Switch(
            value: value,
            onChanged: onToggle,
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _SettingsRowNavigate extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsRowNavigate({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.valueWidget,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary)),
            ),
            if (valueWidget != null) ...[
              valueWidget!,
            ] else if (value != null) ...[
              Text(value!,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
