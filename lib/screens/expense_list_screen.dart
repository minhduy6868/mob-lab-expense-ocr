import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../services/database_helper.dart';
import '../state/auth_controller.dart';
import '../state/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/logout_button.dart';
import '../widgets/vku_logo.dart';

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
    final auth = ref.watch(authProvider);
    final syncLabel = switch (sync.phase) {
      CloudSyncPhase.synced => text.synced,
      CloudSyncPhase.offline => text.offline,
      CloudSyncPhase.checking => text.syncing,
    };
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
                        const VkuLogo(size: 44),
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
                                auth.username.isEmpty ? syncLabel : '${auth.username}, $syncLabel',
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
                  const SizedBox(width: 8),
                  const LogoutButton(),
                ],
              ),
            ),
            GlassSurface(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              radius: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          filtering ? text.filtered : text.thisMonth,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: _isBalanceVisible ? text.hidePassword : text.showPassword,
                        onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                        icon: Icon(
                          _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 48,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isBalanceVisible ? Formatters.formatVND(shownTotal) : '•••••••• đ',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (!filtering) ...[
                    const SizedBox(height: 8),
                    Text(
                      text.thisWeek(Formatters.formatVND(weekTotal)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.navy,
                          ),
                          onPressed: () => context.push('/scan'),
                          icon: const Icon(Icons.document_scanner_rounded),
                          label: Text(text.scanReceipt),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.28)),
                        ),
                        onPressed: () => context.push('/review'),
                        child: Text(text.manualEntry),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Search and Category Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassSurface(
                radius: 16,
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
