import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_text.dart';
import '../state/locale_controller.dart';

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final locale = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.language, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'vi', label: Text(text.vietnamese)),
            ButtonSegment(value: 'en', label: Text(text.english)),
          ],
          selected: {locale.languageCode},
          onSelectionChanged: (selection) {
            ref.read(localeProvider.notifier).setLocale(Locale(selection.first));
          },
        ),
      ],
    );
  }
}
