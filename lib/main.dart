import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'state/expense_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // Mount Riverpod ProviderScope at root of widget tree (Slide 10 & 14)
    const ProviderScope(
      child: VKUExpenseApp(),
    ),
  );
}

class VKUExpenseApp extends ConsumerWidget {
  const VKUExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'VKU Expense OCR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
