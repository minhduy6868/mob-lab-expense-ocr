import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../services/database_helper.dart';

final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, CloudSyncStatus>(
  CloudSyncNotifier.new,
);

class CloudSyncNotifier extends Notifier<CloudSyncStatus> {
  @override
  CloudSyncStatus build() => CloudSyncStatus.checking;

  void apply(CloudSyncStatus status) => state = status;
}

// Riverpod 2 State Controller managing persistent SQLite CRUD (Slide 15 & 18)
class ExpenseListNotifier extends AsyncNotifier<List<ExpenseItem>> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<List<ExpenseItem>> build() async {
    final items = await _loadExpenses();
    _publishSync();
    return items;
  }

  void _publishSync() {
    final status = _db.lastStatus;
    Future.microtask(() {
      if (!ref.mounted) return;
      ref.read(cloudSyncProvider.notifier).apply(status);
    });
  }

  Future<List<ExpenseItem>> _loadExpenses() async {
    try {
      final items = await _db.getAllExpenses();
      if (items.isEmpty) {
        // Preload default VKU sample receipts for first run
        await _seedInitialSamples();
        return await _db.getAllExpenses();
      }
      return items;
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      return [];
    }
  }

  Future<void> addExpense(ExpenseItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.insertExpense(item);
      _publishSync();
      return await _db.getAllExpenses();
    });
  }

  Future<void> updateExpense(ExpenseItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.updateExpense(item);
      _publishSync();
      return await _db.getAllExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    // Optimistic / fast UI update
    final previousState = state.value ?? [];
    state = AsyncValue.data(previousState.where((e) => e.id != id).toList());

    try {
      await _db.deleteExpense(id);
      _publishSync();
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(previousState);
      _publishSync();
    }
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.clearAllExpenses();
      _publishSync();
      return <ExpenseItem>[];
    });
  }

  Future<void> refreshFromCloud() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final items = await _db.getAllExpenses();
      _publishSync();
      return items;
    });
  }

  Future<void> seedSampleData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.clearAllExpenses();
      await _seedInitialSamples();
      _publishSync();
      return await _db.getAllExpenses();
    });
  }

  Future<void> _seedInitialSamples() async {
    final now = DateTime.now();
    final samples = [
      ExpenseItem(
        id: 'sample_1',
        title: 'Highlands Coffee VKU',
        amount: 84000,
        timestamp: now.subtract(const Duration(hours: 3)),
        category: ExpenseCategory.food,
        note: 'Cà phê học nhóm ôn thi cuối kỳ',
        rawOcrText: 'HIGHLANDS COFFEE\nTỔNG CỘNG: 84.000 đ\n22/10/2026',
      ),
      ExpenseItem(
        id: 'sample_2',
        title: 'Co.op Mart Đà Nẵng',
        amount: 245000,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        category: ExpenseCategory.shopping,
        note: 'Mua nhu yếu phẩm và đồ dùng ký túc xá',
        rawOcrText: 'CO.OP MART\nTHANH TOÁN: 245.000\nNgày: 21/10/2026',
      ),
      ExpenseItem(
        id: 'sample_3',
        title: 'Petrolimex Nam Kỳ Khởi Nghĩa',
        amount: 70000,
        timestamp: now.subtract(const Duration(days: 2, hours: 5)),
        category: ExpenseCategory.transport,
        note: 'Đổ xăng xe máy đi học VKU',
        rawOcrText: 'PETROLIMEX\nTỔNG TIỀN: 70.000 đ',
      ),
      ExpenseItem(
        id: 'sample_4',
        title: 'Nhà Sách Fahasa',
        amount: 155000,
        timestamp: now.subtract(const Duration(days: 3, hours: 1)),
        category: ExpenseCategory.education,
        note: 'Giáo trình Lập trình ứng dụng đa nền tảng',
        rawOcrText: 'FAHASA\nTỔNG CỘNG: 155.000 đ',
      ),
      ExpenseItem(
        id: 'sample_5',
        title: 'CGV Vincom Đà Nẵng',
        amount: 130000,
        timestamp: now.subtract(const Duration(days: 4, hours: 4)),
        category: ExpenseCategory.entertainment,
        note: 'Vé xem phim cuối tuần',
        rawOcrText: 'CGV CINEMAS\nTOTAL: 130000 VND',
      ),
      ExpenseItem(
        id: 'sample_6',
        title: 'Nhà Thuốc Long Châu',
        amount: 92000,
        timestamp: now.subtract(const Duration(days: 5, hours: 6)),
        category: ExpenseCategory.health,
        note: 'Vitamin C và khẩu trang y tế',
        rawOcrText: 'FPT LONG CHAU\nTHANH TOÁN: 92.000 đ',
      ),
      ExpenseItem(
        id: 'sample_7',
        title: 'Viettel Telecom Internet',
        amount: 180000,
        timestamp: now.subtract(const Duration(days: 6, hours: 2)),
        category: ExpenseCategory.utilities,
        note: 'Cước Wifi phòng trọ tháng 10',
        rawOcrText: 'VIETTEL TELECOM\nTIỀN CƯỚC: 180.000 đ',
      ),
    ];

    await _db.upsertAll(samples);
  }
}

// Global compile-time safe provider definition (Slide 15)
final expenseListProvider = AsyncNotifierProvider<ExpenseListNotifier, List<ExpenseItem>>(
  ExpenseListNotifier.new,
);

// UI Filter state using Riverpod Notifiers (Slide 15)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class CategoryFilterNotifier extends Notifier<ExpenseCategory?> {
  @override
  ExpenseCategory? build() => null;
  void setCategory(ExpenseCategory? cat) => state = cat;
}

final selectedCategoryFilterProvider = NotifierProvider<CategoryFilterNotifier, ExpenseCategory?>(
  CategoryFilterNotifier.new,
);

// Filtered expenses provider for ListView
final filteredExpensesProvider = Provider<List<ExpenseItem>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final items = asyncExpenses.value ?? [];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final cat = ref.watch(selectedCategoryFilterProvider);

  return items.where((item) {
    final matchesQuery = query.isEmpty ||
        item.title.toLowerCase().contains(query) ||
        (item.note?.toLowerCase().contains(query) ?? false);
    final matchesCat = cat == null || item.category == cat;
    return matchesQuery && matchesCat;
  }).toList();
});

// Grand total calculation (Slide 10)
final grandTotalProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final items = asyncExpenses.value ?? [];
  return items.fold(0.0, (sum, i) => sum + i.amount);
});

// Category total distribution for Donut Chart
final categoryDistributionProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final items = asyncExpenses.value ?? [];
  final map = <ExpenseCategory, double>{};

  for (final item in items) {
    map[item.category] = (map[item.category] ?? 0.0) + item.amount;
  }
  return map;
});

// Weekly spending distribution for Bar Chart (Mon=1 ... Sun=7)
final weeklySpendingProvider = Provider<Map<int, double>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final items = asyncExpenses.value ?? [];
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

  final weeklyMap = {for (int i = 1; i <= 7; i++) i: 0.0};
  for (final item in items) {
    if (item.timestamp.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
      weeklyMap[item.timestamp.weekday] = (weeklyMap[item.timestamp.weekday] ?? 0.0) + item.amount;
    }
  }
  return weeklyMap;
});

// Theme Mode Provider (Light / Dark / System)
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
