import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../services/database_helper.dart';
import '../state/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/install_app_card.dart';

/// Expense List Screen - Flagship Fintech Dashboard
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  bool _isBalanceVisible = true;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshLedger() {
    return ref.read(expenseListProvider.notifier).refreshFromCloud();
  }

  List<Object> _groupRows(List<ExpenseItem> items) {
    final rows = <Object>[];
    String? lastLabel;
    for (final item in items) {
      final label = Formatters.formatDayGroup(item.timestamp);
      if (label != lastLabel) {
        rows.add(label);
        lastLabel = label;
      }
      rows.add(item);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncExpenses = ref.watch(expenseListProvider);
    final filteredItems = ref.watch(filteredExpensesProvider);
    final weekTotal = ref.watch(weeklySpendingProvider).values.fold<double>(0, (sum, value) => sum + value);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final sync = ref.watch(cloudSyncProvider);
    final now = DateTime.now();
    final allItems = asyncExpenses.value ?? [];
    final filtering = currentQuery.trim().isNotEmpty || selectedCategory != null;
    final monthItems = allItems.where(
      (item) => item.timestamp.year == now.year && item.timestamp.month == now.month,
    );
    final shownItems = filtering ? filteredItems : monthItems;
    final shownTotal = shownItems.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top User Profile & Status Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/brand/icon.png',
                            width: 44,
                            height: 44,
                            semanticLabel: 'Logo VKU Ledger',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VKU Ledger',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                switch (sync.phase) {
                                  CloudSyncPhase.synced => text.synced,
                                  CloudSyncPhase.offline => text.offline,
                                  CloudSyncPhase.checking => text.syncing,
                                },
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: sync.phase == CloudSyncPhase.synced
                                      ? (isDark ? AppColors.gold : AppColors.goldInk)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 19,
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        tooltip: 'Đổi giao diện Sáng/Tối',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: InstallAppCard(),
              ),

            // 2. High-End Fintech Wallet Hero Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0C4A6E)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.4 : 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative background bubbles
                  Positioned(
                    right: -25,
                    top: -25,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    bottom: -35,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  filtering ? text.filtered : text.thisMonth,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: Colors.white.withValues(alpha: 0.75),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
                              ),
                              child: Text(
                                '${shownItems.length} hóa đơn',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Large balance figure
                        Text(
                          _isBalanceVisible ? Formatters.formatVND(shownTotal) : '•••••••• đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        if (!filtering) ...[
                          const SizedBox(height: 6),
                          Text(
                            text.thisWeek(Formatters.formatVND(weekTotal)),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 360;
                            final actions = [
                              _buildHeroAction(
                                icon: Icons.document_scanner_rounded,
                                label: text.scanReceipt,
                                isPrimary: true,
                                onTap: () => context.push('/scan'),
                              ),
                              _buildHeroAction(
                                icon: Icons.edit_note_rounded,
                                label: text.manualEntry,
                                isPrimary: false,
                                onTap: () => context.push('/review'),
                              ),
                              _buildHeroAction(
                                icon: Icons.insights_rounded,
                                label: text.charts,
                                isPrimary: false,
                                onTap: () => context.go('/reports'),
                              ),
                              _buildHeroAction(
                                icon: Icons.restart_alt_rounded,
                                label: text.loadSamples,
                                isPrimary: false,
                                onTap: () async {
                                  await ref.read(expenseListProvider.notifier).seedSampleData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(text.samplesLoaded)),
                                    );
                                  }
                                },
                              ),
                            ];
                            if (!stacked) {
                              return Row(
                                children: [
                                  for (var i = 0; i < actions.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(child: actions[i]),
                                  ],
                                ],
                              );
                            }
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: actions[0]),
                                    const SizedBox(width: 8),
                                    Expanded(child: actions[1]),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: actions[2]),
                                    const SizedBox(width: 8),
                                    Expanded(child: actions[3]),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Search and Category Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: text.searchHint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.primary),
                    suffixIcon: currentQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) => ref.read(searchQueryProvider.notifier).setQuery(val),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Pills
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('Tất cả'),
                      selected: selectedCategory == null,
                      onSelected: (_) =>
                          ref.read(selectedCategoryFilterProvider.notifier).setCategory(null),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                  ),
                  ...ExpenseCategory.values.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        avatar: Icon(cat.icon, size: 14, color: cat.color),
                        label: Text(cat.displayName.split(' & ')[0]),
                        selected: selectedCategory == cat,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        onSelected: (selected) {
                          ref.read(selectedCategoryFilterProvider.notifier).setCategory(
                                selected ? cat : null,
                              );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 4. Virtualized Transactions List with Dismissible
            Expanded(
              child: asyncExpenses.when(
                data: (_) {
                  final rows = _groupRows(filteredItems);
                  return RefreshIndicator(
                    onRefresh: _refreshLedger,
                    child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: rows.isEmpty ? 1 : rows.length,
                    itemBuilder: (context, index) {
                      if (rows.isEmpty) {
                        return _LedgerMessage(
                          icon: Icons.receipt_long_outlined,
                          title: currentQuery.isNotEmpty || selectedCategory != null
                              ? text.emptyFilter
                              : text.emptyLedger,
                          body: currentQuery.isNotEmpty || selectedCategory != null
                              ? text.emptyFilterBody
                              : text.emptyLedgerBody,
                          actionLabel: currentQuery.isNotEmpty || selectedCategory != null ? null : text.scanReceipt,
                          onAction: currentQuery.isNotEmpty || selectedCategory != null
                              ? null
                              : () => context.push('/scan'),
                        );
                      }
                      final row = rows[index];
                      if (row is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                          child: Text(
                            row,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final item = row as ExpenseItem;

                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Xóa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: Text('Bạn có chắc muốn xóa khoản chi "${item.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Hủy'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          ref.read(expenseListProvider.notifier).deleteExpense(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã xóa "${item.title}"'),
                              action: SnackBarAction(
                                label: 'Hoàn tác',
                                onPressed: () {
                                  ref.read(expenseListProvider.notifier).addExpense(item);
                                },
                              ),
                            ),
                          );
                        },
                        child: ExpenseSummaryCard(
                          merchant: item.title,
                          amount: item.amount,
                          date: item.timestamp,
                          category: item.category,
                          note: item.note,
                          onTap: () => context.push('/expense/${item.id}'),
                        ),
                      );
                    },
                    ),
                  );
                },
                loading: () => const _LedgerSkeleton(),
                error: (err, stack) => _LedgerMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Không tải được sổ chi',
                  body: 'Kiểm tra mạng rồi thử lại. Bản trên máy vẫn được giữ.',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(expenseListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAction({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.gold : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isPrimary ? AppColors.navy : Colors.white,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPrimary ? AppColors.navy : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _LedgerMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LedgerSkeleton extends StatelessWidget {
  const _LedgerSkeleton();

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 76,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
