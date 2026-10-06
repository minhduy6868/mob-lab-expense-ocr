import 'dart:io';
import 'package:flutter/material.dart';
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
        title: Text(isEditing ? 'Chỉnh sửa chi tiêu' : 'Kiểm tra & Xác nhận OCR'),
        actions: [
          TextButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Lưu'),
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
                // Confidence badge if parsed from OCR
                if (!isEditing && widget.initialParsedReceipt != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: confidence > 0.7
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: confidence > 0.7 ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          confidence > 0.7 ? Icons.verified : Icons.warning_amber_rounded,
                          color: confidence > 0.7 ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Độ tin cậy OCR: ${(confidence * 100).toInt()}% • Vui lòng kiểm tra kỹ số tiền',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
                    borderRadius: BorderRadius.circular(12),
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
                    labelText: 'Tên cửa hàng / Đơn vị bán',
                    prefixIcon: const Icon(Icons.storefront_rounded),
                    helperText: 'Trích xuất tự động từ đầu hóa đơn',
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
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    suffixText: 'VNĐ',
                    helperText: 'Kiểm tra đúng tổng số tiền trên hóa đơn',
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
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày giao dịch',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      Formatters.formatDate(_selectedDate),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection
                Text(
                  'Danh mục chi tiêu',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat.displayName),
                      avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  focusNode: _noteFocus,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm (tùy chọn)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    hintText: 'Ví dụ: Đóng tiền phòng, ăn trưa với bạn...',
                  ),
                ),
                const SizedBox(height: 20),

                // Raw OCR Text Inspector (Slide 41)
                if (_rawOcrText != null && _rawOcrText!.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text(
                      'Xem dữ liệu OCR thô (Raw OCR Text)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    leading: const Icon(Icons.data_object_rounded),
                    initiallyExpanded: _showRawOcr,
                    onExpansionChanged: (val) => setState(() => _showRawOcr = val),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: SelectableText(
                          _rawOcrText!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Submit Button (Slide 28)
                FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    isEditing ? 'Lưu thay đổi' : 'Xác nhận & Lưu vào SQLite',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
