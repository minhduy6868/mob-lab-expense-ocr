import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../state/locale_controller.dart';

class LanguagePicker extends ConsumerWidget {
  final bool compact;

  const LanguagePicker({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final locale = ref.watch(localeProvider);
    final code = locale.languageCode == 'en' ? 'en' : 'vi';
    if (compact) {
      Widget mark(String value, String label) {
        final selected = code == value;
        return TextButton(
          onPressed: () => ref.read(localeProvider.notifier).setLocale(Locale(value)),
          style: TextButton.styleFrom(
            foregroundColor: selected ? AppColors.gold : AppColors.paper.withValues(alpha: 0.72),
            minimumSize: const Size(44, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(label),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark('vi', 'VI'),
          mark('en', 'EN'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.language, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'vi', label: Text(text.vietnamese), tooltip: text.vietnamese),
            ButtonSegment(value: 'en', label: Text(text.english), tooltip: text.english),
          ],
          selected: {code},
          onSelectionChanged: (selection) {
            ref.read(localeProvider.notifier).setLocale(Locale(selection.first));
          },
        ),
      ],
    );
  }
}
