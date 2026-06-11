import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../repositories/firebase_food_repository.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesServiceProvider);
    final notificationTime = prefs.notificationTime;
    final timeStr =
        '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final inviteCodeAsync = ref.watch(inviteCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [

          // ── Account ──
          _SectionHeader(label: 'Account'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.person_outline_rounded,
              label: 'Email',
              value: user?.email ?? 'Non connesso',
              onTap: () {},
              showChevron: false,
            ),
            const _Divider(),
            _SettingsRowNavigate(
              icon: Icons.people_outline_rounded,
              label: 'Gruppo domestico',
              onTap: () => _showHouseholdInfo(context, ref),
              valueWidget: inviteCodeAsync.when(
                data: (code) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.safeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(code ?? 'Connesso',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.safe)),
                ),
                loading: () => const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (error, _) =>
                    const Text('Errore', style: TextStyle(color: AppColors.urgent)),
              ),
            ),
            const _Divider(),
            _SettingsRowNavigate(
              icon: Icons.logout_rounded,
              label: 'Disconnetti',
              onTap: () => _confirmSignOut(context, ref),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Notifications (only on native) ──
          if (!kIsWeb) ...[
            _SectionHeader(label: 'Notifiche'),
            _SettingsCard(children: [
              _SettingsRowSwitch(
                icon: Icons.notifications_outlined,
                label: 'Notifiche push',
                value: true,
                onToggle: (_) async {
                  final svc =
                      await ref.read(notificationServiceProvider.future);
                  await svc.requestPermissions();
                },
              ),
              const _Divider(),
              _SettingsRowNavigate(
                icon: Icons.schedule_outlined,
                label: 'Ora della notifica giornaliera',
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
                label: 'Stato autorizzazioni',
                onTap: () async {
                  final svc =
                      await ref.read(notificationServiceProvider.future);
                  final granted = await svc.requestPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(granted
                          ? 'Notifiche consentite'
                          : 'Autorizzazione negata'),
                    ));
                  }
                },
                valueWidget: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Attive',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // ── Appearance ──
          _SectionHeader(label: 'Aspetto'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.palette_outlined,
              label: 'Tema',
              value: 'Predefinito di sistema',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // ── Data ──
          _SectionHeader(label: 'Dati'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.upload_outlined,
              label: 'Esporta dati',
              onTap: () => _exportData(context, ref),
            ),
          ]),
          const SizedBox(height: 24),

          // ── About ──
          _SectionHeader(label: 'Informazioni'),
          _SettingsCard(children: [
            _SettingsRowNavigate(
              icon: Icons.info_outline_rounded,
              label: 'Versione',
              value: '1.0.0',
              onTap: () {},
              showChevron: false,
            ),
          ]),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Dispens — Il gestore della dispensa della tua casa',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showHouseholdInfo(BuildContext context, WidgetRef ref) async {
    final code = await ref.read(inviteCodeProvider.future);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Gruppo domestico'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Condividi questo codice invito per aggiungere qualcuno al tuo gruppo domestico:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (code != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      color: AppColors.primary,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Codice copiato!')),
                        );
                      },
                    ),
                  ],
                ),
              )
            else
              const Text('Nessun codice invito trovato.',
                  style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnetti'),
        content: const Text('Vuoi davvero disconnetterti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.urgent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Disconnetti'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(authServiceProvider).signOut();
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(firebaseFoodRepositoryProvider);
      if (repo == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nessun gruppo domestico collegato')),
          );
        }
        return;
      }
      final items = await repo.getItems();
      final json = jsonEncode(items.map((e) => e.toJson()).toList());

      // Copy to clipboard as a simple cross-platform export
      await Clipboard.setData(ClipboardData(text: json));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${items.length} alimenti copiati negli appunti in formato JSON'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esportazione non riuscita: $e')),
        );
      }
    }
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
