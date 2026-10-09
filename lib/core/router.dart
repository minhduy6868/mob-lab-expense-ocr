import 'package:go_router/go_router.dart';
import '../models/expense_item.dart';
import '../models/parsed_receipt.dart';
import '../screens/expense_detail_screen.dart';
import '../screens/expense_list_screen.dart';
import '../screens/receipt_review_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/scan_receipt_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // ShellRoute providing persistent NavigationBar (Slide 23)
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/dash',
          builder: (context, state) => const ExpenseListScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanReceiptScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),

    // Dynamic path parameter route /expense/:id (Slide 21)
    GoRoute(
      path: '/expense/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExpenseDetailScreen(id: id);
      },
    ),

    // Review & Verification Screen (Slide 26-28)
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ParsedReceipt) {
          return ReceiptReviewScreen(initialParsedReceipt: extra);
        } else if (extra is ExpenseItem) {
          return ReceiptReviewScreen(existingExpense: extra);
        }
        return const ReceiptReviewScreen();
      },
    ),
  ],
);
