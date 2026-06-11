import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sort_filter_provider.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class SortFilterSheet extends ConsumerStatefulWidget {
  const SortFilterSheet({super.key});

  @override
  ConsumerState<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends ConsumerState<SortFilterSheet> {
  static const _rangeDays = [3, 7, 30];

  @override
  Widget build(BuildContext context) {
    final sf = ref.watch(sortFilterProvider);
    final notifier = ref.read(sortFilterProvider.notifier);
    final allTags = ref.watch(allTagsProvider);

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ordina e filtra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Sort by ──
                  _sectionLabel('Ordina per'),
                  const SizedBox(height: 8),
                  _SortRadioGroup(
                    value: sf.sortBy,
                    onChanged: notifier.setSortBy,
                  ),
                  const SizedBox(height: 20),

                  // ── Filter by Tags ──
                  _sectionLabel('Filtra per tag'),
                  const SizedBox(height: 10),
                  if (allTags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Non ci sono ancora tag: aggiungili ai tuoi alimenti per filtrare qui.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allTags.map((tag) {
                        final selected = sf.selectedTags.contains(tag);
                        return _FilterChip(
                          label: tag,
                          selected: selected,
                          onTap: () => notifier.toggleTag(tag),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // ── Expiration Range ──
                  _sectionLabel('Intervallo di scadenza'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ..._rangeDays.map((d) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: '$d giorni',
                              selected: sf.expirationRangeDays == d,
                              onTap: () => notifier.setExpirationRange(
                                  sf.expirationRangeDays == d ? null : d),
                            ),
                          )),
                      _FilterChip(
                        label: 'Tutti',
                        selected: sf.expirationRangeDays == null,
                        onTap: () => notifier.setExpirationRange(null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Expiration Type ──
                  _sectionLabel('Tipo di scadenza'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _FilterChip(
                        label: 'Da consumarsi entro',
                        selected: sf.expiryTypeFilter == ExpiryType.strict,
                        onTap: () => notifier.setExpiryTypeFilter(
                          sf.expiryTypeFilter == ExpiryType.strict
                              ? null
                              : ExpiryType.strict,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Preferibilmente entro',
                        selected: sf.expiryTypeFilter == ExpiryType.bestBefore,
                        onTap: () => notifier.setExpiryTypeFilter(
                          sf.expiryTypeFilter == ExpiryType.bestBefore
                              ? null
                              : ExpiryType.bestBefore,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      notifier.reset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Azzera filtri',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navActive,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Applica filtri'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ));
  }
}

// ───────────────────────────────────────────────
//  Sort radio group
// ───────────────────────────────────────────────
class _SortRadioGroup extends StatelessWidget {
  final SortOption value;
  final ValueChanged<SortOption> onChanged;

  const _SortRadioGroup({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: SortOption.values.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          final label = switch (option) {
            SortOption.expirationDate => 'Data di scadenza',
            SortOption.name => 'Nome',
            SortOption.dateAdded => 'Data di inserimento',
          };
          return Column(
            children: [
              InkWell(
                onTap: () => onChanged(option),
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: i == SortOption.values.length - 1
                      ? const Radius.circular(12)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _RadioDot(selected: option == value),
                      const SizedBox(width: 10),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              if (i < SortOption.values.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 0),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Selectable filter chip
// ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navActive : AppColors.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navActive : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.chipText,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Custom radio dot (avoids deprecated Radio API)
// ───────────────────────────────────────────────
class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 6 : 2,
        ),
        color: selected ? AppColors.primary : Colors.transparent,
      ),
    );
  }
}
