import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final expense = items.where((item) => item.id == id).firstOrNull;

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
        title: const Text('Hóa Đơn Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Sao chép thông tin',
            onPressed: () {
              final text = 'Chi tiêu: ${expense.title}\nSố tiền: ${Formatters.formatVND(expense.amount)}\nNgày: ${Formatters.formatDateTime(expense.timestamp)}\nDanh mục: ${cat.displayName}';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép chi tiết chi tiêu!')),
              );
            },
          ),
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
                  content: Text('Bạn có chắc muốn xóa khoản chi "${expense.title}"?'),
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
              // 1. Digital Receipt Voucher Card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Receipt Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cat.color.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(cat.icon, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            expense.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatVND(expense.amount),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.error,
                              fontSize: 28,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: cat.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.displayName,
                                  style: TextStyle(
                                    color: cat.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Serrated separator line representation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(
                          30,
                          (index) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 1.5,
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Receipt Attributes
                    Padding(
                      padding: const EdgeInsets.all(20.0),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Image preview if available
              if (!kIsWeb &&
                  expense.receiptImagePath != null &&
                  File(expense.receiptImagePath!).existsSync()) ...[
                Text(
                  'Hình ảnh hóa đơn đã quét',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 280),
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
                  'Văn bản OCR nhận diện được',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    expense.rawOcrText!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
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
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
