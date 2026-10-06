import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/formatters.dart';
import '../state/expense_providers.dart';

/// ExpenseDetailScreen reached via /expense/:id (Slide 21)
class ExpenseDetailScreen extends ConsumerWidget {
  final String id;

  const ExpenseDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncExpenses = ref.watch(expenseListProvider);
    final items = asyncExpenses.value ?? [];
    final expense = items.cast().firstWhere(
      (e) => e.id == id,
      orElse: () => null,
    );

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chi tiêu')),
        body: const Center(
          child: Text('Không tìm thấy khoản chi tiêu hoặc đã bị xóa.'),
        ),
      );
    }

    final cat = expense.category;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chi tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              context.push('/review', extra: expense);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Xóa',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Bạn có chắc muốn xóa "${expense.title}"?'),
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

              if (confirm == true) {
                ref.read(expenseListProvider.notifier).deleteExpense(expense.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã xóa "${expense.title}"')),
                  );
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cat.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cat.color,
                      child: Icon(cat.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expense.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.formatVND(expense.amount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(cat.displayName),
                      backgroundColor: cat.color.withValues(alpha: 0.2),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Detail attributes
              Card(
                elevation: 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Thời gian',
                        value: Formatters.formatDateTime(expense.timestamp),
                        theme: theme,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Mã giao dịch',
                        value: expense.id,
                        theme: theme,
                      ),
                      if (expense.note != null && expense.note!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.notes_rounded,
                          label: 'Ghi chú',
                          value: expense.note!,
                          theme: theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Image preview if available
              if (expense.receiptImagePath != null &&
                  File(expense.receiptImagePath!).existsSync()) ...[
                Text(
                  'Hình ảnh hóa đơn đã quét',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.file(
                      File(expense.receiptImagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Raw OCR text section
              if (expense.rawOcrText != null && expense.rawOcrText!.isNotEmpty) ...[
                Text(
                  'Dữ liệu văn bản OCR',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    expense.rawOcrText!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
