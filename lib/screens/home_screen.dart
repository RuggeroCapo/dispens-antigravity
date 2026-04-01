import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../providers/sort_filter_provider.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import 'add_edit_food_screen.dart';
import 'sort_filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredFoodListProvider);
    final sf = ref.watch(sortFilterProvider);
    final hasActiveFilters = sf.selectedTags.isNotEmpty ||
        sf.expirationRangeDays != null ||
        sf.expiryTypeFilter != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: _searchOpen
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search items…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(sortFilterProvider.notifier).setSearchQuery('');
                          setState(() => _searchOpen = false);
                        },
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) =>
                        ref.read(sortFilterProvider.notifier).setSearchQuery(v),
                  )
                : const Text('My Pantry'),
            actions: [
              if (!_searchOpen)
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 24),
                  color: AppColors.textPrimary,
                  onPressed: () => setState(() => _searchOpen = true),
                ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt_rounded, size: 24),
                    color: AppColors.textPrimary,
                    onPressed: () => _showFilterSheet(context),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8), // icon padding (8px) + 8px = 16px to icon center + 4px extra? Action icons are 48x48 (padding 8px inside, leaving 24px icon). Total right margin to icon = 20px (12px button padding right + 8px sizedbox).
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 4, bottom: 100),
            sliver: filteredAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(hasFilters: hasActiveFilters),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _FoodItemCard(item: items[i]),
                    childCount: items.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.urgent)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditFoodScreen()),
        ),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SortFilterSheet(),
    );
  }
}

// ───────────────────────────────────────────────
//  Food item card
// ───────────────────────────────────────────────
class _FoodItemCard extends ConsumerWidget {
  final FoodItem item;
  const _FoodItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final daysToExpiry = item.expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays; // actually better to just rely on the existing logic

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.urgent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        ref.read(foodListProvider.notifier).deleteItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed'),
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.primaryLight,
              onPressed: () {},
            ),
          ),
        );
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditFoodScreen(foodItem: item)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(item.description!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExpiryBadge(
                      item: item,
                      daysToExpiry: daysToExpiry,
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.tags.map((t) => _TagChip(label: t)).toList(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Expiry badge chip
// ───────────────────────────────────────────────
class _ExpiryBadge extends StatelessWidget {
  final FoodItem item;
  final int daysToExpiry;

  const _ExpiryBadge({
    required this.item,
    required this.daysToExpiry,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData? icon;
    String dateStr = DateFormat('MMM dd').format(item.expiryDate);

    final isExpired = daysToExpiry < 0;
    final isCritical = daysToExpiry >= 0 && daysToExpiry <= 2 || isExpired;
    final isWarning = daysToExpiry >= 3 && daysToExpiry <= 5;

    if (isCritical) {
      bg = AppColors.urgentBg;
      text = AppColors.urgent;
      icon = Icons.warning_amber_rounded;
    } else if (isWarning) {
      bg = AppColors.warningBg;
      text = AppColors.warning;
      icon = Icons.schedule_rounded;
    } else {
      bg = AppColors.safeBg;
      text = AppColors.safe;
      icon = null;
    }

    String textContent;
    if (isExpired) {
      textContent = 'Expired · $dateStr';
    } else if (daysToExpiry == 0) {
      textContent = 'Expires today · $dateStr';
    } else if (daysToExpiry == 1) {
      textContent = 'Expires tomorrow · $dateStr';
    } else {
      textContent = '$daysToExpiry days left · $dateStr';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 14, color: text),
            ),
          Text(
            textContent,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Tag chip
// ───────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.chipText,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Empty state
// ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.filter_alt_off_rounded
                    : Icons.kitchen_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No items match your filters' : 'Your pantry is empty',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting or clearing your filters.'
                  : 'Tap + to add your first food item.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
