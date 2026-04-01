import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../providers/food_provider.dart';

enum SortOption { expirationDate, name, dateAdded }

class SortFilterState {
  final SortOption sortBy;
  final Set<String> selectedTags;
  final int? expirationRangeDays;
  final ExpiryType? expiryTypeFilter;
  final String searchQuery;

  const SortFilterState({
    this.sortBy = SortOption.expirationDate,
    this.selectedTags = const {},
    this.expirationRangeDays,
    this.expiryTypeFilter,
    this.searchQuery = '',
  });

  SortFilterState copyWith({
    SortOption? sortBy,
    Set<String>? selectedTags,
    int? Function()? expirationRangeDays,
    ExpiryType? Function()? expiryTypeFilter,
    String? searchQuery,
  }) {
    return SortFilterState(
      sortBy: sortBy ?? this.sortBy,
      selectedTags: selectedTags ?? this.selectedTags,
      expirationRangeDays: expirationRangeDays != null ? expirationRangeDays() : this.expirationRangeDays,
      expiryTypeFilter: expiryTypeFilter != null ? expiryTypeFilter() : this.expiryTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SortFilterNotifier extends Notifier<SortFilterState> {
  @override
  SortFilterState build() => const SortFilterState();

  void setSortBy(SortOption option) => state = state.copyWith(sortBy: option);

  void toggleTag(String tag) {
    final tags = Set<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  void setExpirationRange(int? days) =>
      state = state.copyWith(expirationRangeDays: () => days);

  void setExpiryTypeFilter(ExpiryType? type) =>
      state = state.copyWith(expiryTypeFilter: () => type);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void reset() => state = const SortFilterState();
}

final sortFilterProvider =
    NotifierProvider<SortFilterNotifier, SortFilterState>(SortFilterNotifier.new);

/// All unique tags currently saved across every food item, sorted A-Z.
final allTagsProvider = Provider<List<String>>((ref) {
  final foodAsync = ref.watch(foodListProvider);
  return foodAsync.whenOrNull(data: (items) {
    final tagSet = <String>{};
    for (final item in items) {
      tagSet.addAll(item.tags);
    }
    final sorted = tagSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }) ?? [];
});

final filteredFoodListProvider = Provider<AsyncValue<List<FoodItem>>>((ref) {
  final foodAsync = ref.watch(foodListProvider);
  final sf = ref.watch(sortFilterProvider);

  return foodAsync.whenData((items) {
    var result = List<FoodItem>.from(items);

    if (sf.searchQuery.isNotEmpty) {
      final q = sf.searchQuery.toLowerCase();
      result = result.where((i) =>
          i.name.toLowerCase().contains(q) ||
          (i.description?.toLowerCase().contains(q) ?? false)).toList();
    }

    if (sf.selectedTags.isNotEmpty) {
      result = result.where((i) =>
          i.tags.any((t) => sf.selectedTags.contains(t))).toList();
    }

    if (sf.expiryTypeFilter != null) {
      result = result.where((i) => i.expiryType == sf.expiryTypeFilter).toList();
    }

    if (sf.expirationRangeDays != null) {
      final now = DateTime.now();
      final limit = now.add(Duration(days: sf.expirationRangeDays!));
      result = result.where((i) => i.expiryDate.isBefore(limit)).toList();
    }

    switch (sf.sortBy) {
      case SortOption.expirationDate:
        result.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      case SortOption.name:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortOption.dateAdded:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  });
});
