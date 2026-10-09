import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../services/web_install.dart';
import 'vku_logo.dart';

class InstallAppCard extends StatelessWidget {
  const InstallAppCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final text = AppText.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const VkuLogo(size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.installTitle, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(text.installBody, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final outcome = await promptPwaInstall();
                    if (!context.mounted || outcome == 'accepted') return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(text.installHelp)),
                    );
                  },
                  icon: const Icon(Icons.install_mobile_rounded),
                  label: Text(text.addToHome),
                ),
                OutlinedButton.icon(
                  onPressed: downloadAndroidApk,
                  icon: const Icon(Icons.android_rounded),
                  label: Text(text.downloadApk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
