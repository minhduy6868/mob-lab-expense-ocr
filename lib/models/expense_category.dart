import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  utilities,
  entertainment,
  health,
  education,
  other;

  String get displayName => switch (this) {
        ExpenseCategory.food => 'Ăn uống & Cà phê',
        ExpenseCategory.transport => 'Đi lại & Xăng xe',
        ExpenseCategory.shopping => 'Mua sắm & Siêu thị',
        ExpenseCategory.utilities => 'Điện nước & Tiện ích',
        ExpenseCategory.entertainment => 'Giải trí & Phim',
        ExpenseCategory.health => 'Y tế & Sức khỏe',
        ExpenseCategory.education => 'Học tập & Sách vở',
        ExpenseCategory.other => 'Khác',
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant,
        ExpenseCategory.transport => Icons.directions_car,
        ExpenseCategory.shopping => Icons.shopping_bag,
        ExpenseCategory.utilities => Icons.bolt,
        ExpenseCategory.entertainment => Icons.movie,
        ExpenseCategory.health => Icons.local_hospital,
        ExpenseCategory.education => Icons.school,
        ExpenseCategory.other => Icons.receipt_long,
      };

  Color get color => switch (this) {
        ExpenseCategory.food => const Color(0xFFEF6C00), // Orange
        ExpenseCategory.transport => const Color(0xFF1976D2), // Blue
        ExpenseCategory.shopping => const Color(0xFF7B1FA2), // Purple
        ExpenseCategory.utilities => const Color(0xFF00796B), // Teal
        ExpenseCategory.entertainment => const Color(0xFFD81B60), // Pink
        ExpenseCategory.health => const Color(0xFFE53935), // Red
        ExpenseCategory.education => const Color(0xFF0288D1), // Light Blue
        ExpenseCategory.other => const Color(0xFF5D4037), // Brown
      };

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
