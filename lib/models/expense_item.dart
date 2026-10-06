import 'expense_category.dart';

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final DateTime timestamp;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? note;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    this.category = ExpenseCategory.other,
    this.receiptImagePath,
    this.rawOcrText,
    this.note,
  });

  // Named draft constructor as shown in Slide 15
  ExpenseItem.draft(this.title, this.amount, {this.category = ExpenseCategory.other})
      : id = 'draft_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = DateTime.now(),
        receiptImagePath = null,
        rawOcrText = null,
        note = null;

  String get formattedDate {
    final d = timestamp;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'receiptImagePath': receiptImagePath,
      'rawOcrText': rawOcrText,
      'note': note,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      category: ExpenseCategory.fromString(map['category'] as String?),
      receiptImagePath: map['receiptImagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      note: map['note'] as String?,
    );
  }

  ExpenseItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? timestamp,
    ExpenseCategory? category,
    String? receiptImagePath,
    String? rawOcrText,
    String? note,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      note: note ?? this.note,
    );
  }
}
