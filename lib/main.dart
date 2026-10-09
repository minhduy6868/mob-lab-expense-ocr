import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'l10n/app_text.dart';
import 'services/database_helper.dart';
import 'state/auth_controller.dart';
import 'state/expense_providers.dart';
import 'state/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
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
    final locale = ref.watch(localeProvider);
    ref.watch(authProvider);

    return MaterialApp.router(
      title: 'VKU Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppTextDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
