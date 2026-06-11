import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import 'add_edit_food_screen.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodAsync = ref.watch(foodListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Avvisi'),
        actions: [
          foodAsync.whenOrNull(
            data: (items) {
              final upcoming = _getUpcomingItems(items);
              if (upcoming.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${upcoming.length} in arrivo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: foodAsync.when(
        data: (items) => _buildAlertList(context, items),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(
          child: Text('Errore: $e',
              style: const TextStyle(color: AppColors.urgent)),
        ),
      ),
    );
  }

  List<FoodItem> _getUpcomingItems(List<FoodItem> items) {
    final now = DateTime.now();
    return items
        .where((i) => i.expiryDate.difference(now).inDays <= 7)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  Widget _buildAlertList(BuildContext context, List<FoodItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final expired = items.where((i) {
      final d = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return d.isBefore(today);
    }).toList();

    final todayItems = items.where((i) {
      final d = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return d.isAtSameMomentAs(today);
    }).toList();

    final thisWeek = items.where((i) {
      final d = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return d.isAfter(today) &&
          d.isBefore(today.add(const Duration(days: 7)));
    }).toList();

    final later = items.where((i) {
      final d = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return !d.isBefore(today.add(const Duration(days: 7)));
    }).toList();

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        if (expired.isNotEmpty) ...[
          _SectionHeader(label: 'Scaduti'),
          ...expired.map((i) => _AlertCard(item: i, urgency: _Urgency.expired)),
          const SizedBox(height: 8),
        ],
        if (todayItems.isNotEmpty) ...[
          _SectionHeader(label: 'Oggi'),
          ...todayItems.map((i) => _AlertCard(item: i, urgency: _Urgency.today)),
          const SizedBox(height: 8),
        ],
        if (thisWeek.isNotEmpty) ...[
          _SectionHeader(label: 'Questa settimana'),
          ...thisWeek.map((i) => _AlertCard(item: i, urgency: _Urgency.thisWeek)),
          const SizedBox(height: 8),
        ],
        if (later.isNotEmpty) ...[
          _SectionHeader(label: 'Più avanti'),
          ...later.map((i) => _AlertCard(item: i, urgency: _Urgency.later)),
          const SizedBox(height: 8),
        ],
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF4A7FA5)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Gli avvisi vengono inviati ogni giorno alle 09:00. Puoi modificarlo nelle impostazioni.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A7FA5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_outlined,
                  size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            const Text('Nessun avviso',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Tutti i tuoi alimenti rientrano ancora nella data di consumo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

enum _Urgency { expired, today, thisWeek, later }

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
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

class _AlertCard extends StatelessWidget {
  final FoodItem item;
  final _Urgency urgency;

  const _AlertCard({required this.item, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = item.expiryDate.difference(now).inDays;

    Color iconBg;
    Color iconColor;
    IconData iconData;
    String subtitle;
    String? dateStr;

    switch (urgency) {
      case _Urgency.expired:
        iconBg = AppColors.urgentBg;
        iconColor = AppColors.urgent;
        iconData = Icons.warning_rounded;
        subtitle =
            'Scaduto da ${daysLeft.abs()} giorn${daysLeft.abs() == 1 ? 'o' : 'i'} · ${item.expiryType.shortLabel}';
      case _Urgency.today:
        iconBg = AppColors.urgentBg;
        iconColor = AppColors.urgent;
        iconData = Icons.warning_amber_rounded;
        subtitle = 'Scade oggi · ${item.expiryType.shortLabel}';
      case _Urgency.thisWeek:
        iconBg = AppColors.warningBg;
        iconColor = AppColors.warning;
        iconData = Icons.notifications_outlined;
        subtitle =
            'Scade tra $daysLeft giorn${daysLeft == 1 ? 'o' : 'i'} · ${item.expiryType.shortLabel}';
        dateStr = DateFormat('dd MMM', 'it').format(item.expiryDate);
      case _Urgency.later:
        iconBg = AppColors.chipBg;
        iconColor = AppColors.textSecondary;
        iconData = Icons.notifications_none_outlined;
        subtitle = item.expiryType.shortLabel;
        dateStr = DateFormat('dd MMM', 'it').format(item.expiryDate);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddEditFoodScreen(foodItem: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (dateStr != null)
              Text(dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
          ],
        ),
      ),
    );
  }
}
