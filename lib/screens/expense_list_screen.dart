import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/formatters.dart';
import '../models/expense_category.dart';
import '../state/expense_providers.dart';
import '../widgets/expense_summary_card.dart';

/// Expense List Screen - Flagship Fintech Dashboard
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncExpenses = ref.watch(expenseListProvider);
    final filteredItems = ref.watch(filteredExpensesProvider);
    final grandTotal = ref.watch(grandTotalProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final currentQuery = ref.watch(searchQueryProvider);

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
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'VKU',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Chào bạn, Sinh viên VKU! 👋',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Học kỳ 1 • Quản lý chi tiêu AI',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
                                  'Tổng chi tiêu tháng này',
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
                                '${filteredItems.length} hóa đơn',
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

                        // Large balance figure
                        Text(
                          _isBalanceVisible ? Formatters.formatVND(grandTotal) : '•••••••• đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action dock inside card
                        Row(
                          children: [
                            Expanded(
                              child: _buildHeroAction(
                                icon: Icons.document_scanner_rounded,
                                label: 'Quét AI',
                                isPrimary: true,
                                onTap: () => context.push('/scan'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildHeroAction(
                                icon: Icons.edit_note_rounded,
                                label: 'Nhập tay',
                                isPrimary: false,
                                onTap: () => context.push('/review'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildHeroAction(
                                icon: Icons.insights_rounded,
                                label: 'Biểu đồ',
                                isPrimary: false,
                                onTap: () => context.go('/reports'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildHeroAction(
                                icon: Icons.restart_alt_rounded,
                                label: 'Nạp mẫu',
                                isPrimary: false,
                                onTap: () async {
                                  await ref.read(expenseListProvider.notifier).seedSampleData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã nạp 7 hóa đơn mẫu thực tế!')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
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
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cửa hàng, nội dung chi tiêu...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.primary),
                    suffixIcon: currentQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            onPressed: () => ref.read(searchQueryProvider.notifier).setQuery(''),
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
              height: 38,
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
                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có khoản chi tiêu nào',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentQuery.isNotEmpty
                                  ? 'Không tìm thấy kết quả phù hợp với "$currentQuery"'
                                  : 'Nhấn "Quét AI" để bóc tách hóa đơn tự động qua camera',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
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
          color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isPrimary ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? const Color(0xFF1E3A8A) : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
