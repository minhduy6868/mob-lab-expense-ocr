import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/widgets/animated_donut_chart.dart';
import 'package:vku_expense_ocr/widgets/expense_summary_card.dart';

void main() {
  testWidgets('ExpenseSummaryCard renders merchant, date, and VND amount', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSummaryCard(
            merchant: 'Highlands Coffee',
            amount: 65000,
            date: DateTime(2026, 10, 22),
            category: ExpenseCategory.food,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Highlands Coffee'), findsOneWidget);
    expect(find.text('65.000 đ'), findsOneWidget);
    expect(find.text('22/10/2026'), findsOneWidget);

    await tester.tap(find.byType(ExpenseSummaryCard));
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedDonutChart renders total amount label and legend', (WidgetTester tester) async {
    final data = {
      ExpenseCategory.food: 100000.0,
      ExpenseCategory.transport: 50000.0,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedDonutChart(
            data: data,
            totalAmount: 150000,
          ),
        ),
      ),
    );

    expect(find.text('Tổng chi tiêu'), findsOneWidget);
    expect(find.text('150.000 đ'), findsOneWidget);
  });
}
