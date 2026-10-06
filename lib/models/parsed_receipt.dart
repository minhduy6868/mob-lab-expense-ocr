import 'expense_category.dart';

class ReceiptLineItem {
  final String description;
  final double amount;

  const ReceiptLineItem({
    required this.description,
    required this.amount,
  });
}

class ParsedReceipt {
  final String merchantName;
  final double? totalAmount;
  final DateTime? date;
  final ExpenseCategory suggestedCategory;
  final String rawText;
  final double confidenceScore;
  final List<ReceiptLineItem> lineItems;
  final String? localImagePath;

  const ParsedReceipt({
    required this.merchantName,
    this.totalAmount,
    this.date,
    this.suggestedCategory = ExpenseCategory.other,
    required this.rawText,
    this.confidenceScore = 0.85,
    this.lineItems = const [],
    this.localImagePath,
  });

  ParsedReceipt copyWith({
    String? merchantName,
    double? totalAmount,
    DateTime? date,
    ExpenseCategory? suggestedCategory,
    String? rawText,
    double confidenceScore = 0.85,
    List<ReceiptLineItem>? lineItems,
    String? localImagePath,
  }) {
    return ParsedReceipt(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      rawText: rawText ?? this.rawText,
      confidenceScore: confidenceScore,
      lineItems: lineItems ?? this.lineItems,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }
}
