import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Regex Heuristic Tests', () {
    test('Extracts Highlands Coffee total and date correctly', () {
      const rawText = '''
HIGHLANDS COFFEE VKU
HÓA ĐƠN THANH TOÁN
Ngày: 22/10/2026 14:15
Phin Sữa Đá Size L         39.000
Trà Thạch Đào Size M       54.000
TỔNG CỘNG:               122.040 đ
Thanh toán: Tiền mặt
''';

      final parsed = ReceiptParser.parse(rawText);
      expect(parsed.merchantName, 'Highlands Coffee');
      expect(parsed.totalAmount, 122040.0);
      expect(parsed.date?.year, 2026);
      expect(parsed.date?.month, 10);
      expect(parsed.date?.day, 22);
      expect(parsed.suggestedCategory, ExpenseCategory.food);
    });

    test('Extracts Co.op Mart total with comma/dot formats', () {
      const rawText = '''
CO.OP MART DA NANG
HOA DON BAN LE
Ngay: 20/10/2026 18:40
Mi Hao Hao Sa Te   118.000
THANH TOAN: 345.500 VNĐ
Khach dua: 400.000
''';

      final parsed = ReceiptParser.parse(rawText);
      expect(parsed.merchantName, 'Co.op Mart');
      expect(parsed.totalAmount, 345500.0);
      expect(parsed.suggestedCategory, ExpenseCategory.shopping);
    });

    test('Extracts WinMart comma total format "TỔNG TIỀN: 185,000 đ"', () {
      const rawText = '''
WINMART+ CAM LE
PHIEU TINH TIEN
Ngay: 19/10/2026
TỔNG TIỀN: 185,000 đ
''';

      final total = ReceiptParser.extractTotal(rawText);
      expect(total, 185000.0);
    });

    test('Extracts Petrolimex transport category and total', () {
      const rawText = '''
PETROLIMEX CUA HANG XANG DAU SO 12
Ngay: 18/10/2026
TỔNG TIỀN: 80.000 đ
''';

      final parsed = ReceiptParser.parse(rawText);
      expect(parsed.merchantName, 'Petrolimex');
      expect(parsed.totalAmount, 80000.0);
      expect(parsed.suggestedCategory, ExpenseCategory.transport);
    });
  });

  group('Formatters Tests', () {
    test('Formats VND properly with dot thousands separator', () {
      expect(Formatters.formatVND(150000), '150.000 đ');
      expect(Formatters.formatVND(2450000), '2.450.000 đ');
      expect(Formatters.formatVND(0), '0 đ');
    });

    test('Formats dates correctly', () {
      final date = DateTime(2026, 10, 22);
      expect(Formatters.formatDate(date), '22/10/2026');
    });

    test('Groups today and yesterday relative to a fixed day', () {
      final today = DateTime(2026, 10, 9);
      expect(Formatters.formatDayGroup(DateTime(2026, 10, 9, 8), today: today), 'Hôm nay');
      expect(Formatters.formatDayGroup(DateTime(2026, 10, 8, 21), today: today), 'Hôm qua');
      expect(Formatters.formatDayGroup(DateTime(2026, 10, 5), today: today), 'Th 2, 05/10/2026');
    });
  });
}
