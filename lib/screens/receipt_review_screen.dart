import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/formatters.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../models/parsed_receipt.dart';
import '../state/expense_providers.dart';

/// Review & Verification Screen (Slide 26-28, 41)
/// Features Form, GlobalKey of FormState, TextEditingController,
/// FocusNode, AutovalidateMode, and confidence inspection.
class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final ParsedReceipt? initialParsedReceipt;
  final ExpenseItem? existingExpense;

  const ReceiptReviewScreen({
    super.key,
    this.initialParsedReceipt,
    this.existingExpense,
  });

  @override
  ConsumerState<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late final FocusNode _merchantFocus;
  late final FocusNode _amountFocus;
  late final FocusNode _noteFocus;

  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _showRawOcr = false;
  String? _imagePath;
  String? _rawOcrText;

  @override
  void initState() {
    super.initState();
    final parsed = widget.initialParsedReceipt;
    final existing = widget.existingExpense;

    final initialMerchant = existing?.title ?? parsed?.merchantName ?? '';
    final initialAmount = existing != null
        ? existing.amount.toStringAsFixed(0)
        : (parsed?.totalAmount != null ? parsed!.totalAmount!.toStringAsFixed(0) : '');
    final initialNote = existing?.note ?? '';

    _merchantController = TextEditingController(text: initialMerchant);
    _amountController = TextEditingController(text: initialAmount);
    _noteController = TextEditingController(text: initialNote);

    _merchantFocus = FocusNode();
    _amountFocus = FocusNode();
    _noteFocus = FocusNode();

    _selectedDate = existing?.timestamp ?? parsed?.date ?? DateTime.now();
    _selectedCategory = existing?.category ?? parsed?.suggestedCategory ?? ExpenseCategory.other;
    _imagePath = existing?.receiptImagePath ?? parsed?.localImagePath;
    _rawOcrText = existing?.rawOcrText ?? parsed?.rawText;
  }

  @override
  void dispose() {
    // Week 7 Slide 29: ALWAYS dispose controllers and focus nodes to prevent memory leaks!
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _merchantFocus.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final merchant = _merchantController.text.trim();
      final amount = double.parse(_amountController.text.replaceAll(',', '').replaceAll('.', ''));
      final note = _noteController.text.trim();

      if (widget.existingExpense != null) {
        // Update existing expense
        final updated = widget.existingExpense!.copyWith(
          title: merchant,
          amount: amount,
          timestamp: _selectedDate,
          category: _selectedCategory,
          note: note.isNotEmpty ? note : null,
        );
        ref.read(expenseListProvider.notifier).updateExpense(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' Đã cập nhật khoản chi!')),
        );
      } else {
        // Add new expense
        final newItem = ExpenseItem(
          id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
          title: merchant,
          amount: amount,
          timestamp: _selectedDate,
          category: _selectedCategory,
          receiptImagePath: _imagePath,
          rawOcrText: _rawOcrText,
          note: note.isNotEmpty ? note : null,
        );
        ref.read(expenseListProvider.notifier).addExpense(newItem);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' Đã lưu khoản chi từ hóa đơn!')),
        );
      }

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingExpense != null;
    final confidence = widget.initialParsedReceipt?.confidenceScore ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh Sửa Chi Tiêu' : 'Kiểm Tra & Xác Nhận OCR'),
        actions: [
          TextButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Lưu lại', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Confidence badge card
                if (!isEditing && widget.initialParsedReceipt != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: confidence > 0.7
                            ? [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF047857).withValues(alpha: 0.08)]
                            : [const Color(0xFFF59E0B).withValues(alpha: 0.15), const Color(0xFFB45309).withValues(alpha: 0.08)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: confidence > 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: confidence > 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Độ tin cậy OCR AI: ${(confidence * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: confidence > 0.7 ? const Color(0xFF047857) : const Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Các trường đã được tự động điền qua Heuristics Regex. Bạn có thể kiểm tra và chỉnh sửa trước khi lưu.',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Thumbnail preview if image attached
                if (_imagePath != null && File(_imagePath!).existsSync()) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 160,
                      color: Colors.black12,
                      child: Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Merchant Name Field (Slide 27)
                TextFormField(
                  controller: _merchantController,
                  focusNode: _merchantFocus,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Tên cửa hàng / Đơn vị cung cấp',
                    prefixIcon: const Icon(Icons.storefront_rounded),
                    helperText: 'Tự động trích xuất từ tiêu đề hóa đơn',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên cửa hàng' : null,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_amountFocus),
                ),
                const SizedBox(height: 16),

                // Total Amount Field (Slide 27)
                TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Tổng tiền thanh toán (VNĐ)',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    suffixText: 'VNĐ',
                    helperText: 'Số tiền cuối cùng cần thanh toán',
                  ),
                  validator: (v) {
                    final clean = v?.replaceAll(',', '').replaceAll('.', '') ?? '';
                    final n = double.tryParse(clean);
                    return (n == null || n <= 0)
                        ? 'Vui lòng nhập số tiền hợp lệ (> 0)'
                        : null;
                  },
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_noteFocus),
                ),
                const SizedBox(height: 16),

                // Date Picker row
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày giao dịch',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatDate(_selectedDate),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Category Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh mục chi tiêu',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _selectedCategory.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedCategory.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color : cat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat.color : cat.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected ? Colors.white : cat.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.displayName.split(' & ')[0],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  focusNode: _noteFocus,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm (tùy chọn)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    hintText: 'Ví dụ: Đóng quỹ lớp, ăn trưa với bạn bè VKU...',
                  ),
                ),
                const SizedBox(height: 20),

                // Raw OCR Text Inspector (Slide 41)
                if (_rawOcrText != null && _rawOcrText!.isNotEmpty) ...[
                  Card(
                    elevation: 0.6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: const Text(
                        'Xem dữ liệu OCR thô (Raw Text Inspector)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(Icons.data_object_rounded, size: 20),
                      initiallyExpanded: _showRawOcr,
                      onExpansionChanged: (val) => setState(() => _showRawOcr = val),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _rawOcrText!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã sao chép văn bản OCR!')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Sao chép'),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                ),
                                child: SelectableText(
                                  _rawOcrText!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Submit Button (Slide 28)
                FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    isEditing ? 'Lưu Thay Đổi' : 'Xác Nhận & Lưu Vào SQLite',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
