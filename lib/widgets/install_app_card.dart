import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../services/web_install.dart';
import 'liquid_glass.dart';
import 'vku_logo.dart';

class InstallAppCard extends StatelessWidget {
  const InstallAppCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final text = AppText.of(context);
    final theme = Theme.of(context);

    return GlassCard(
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
                      Text(
                        text.installBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 48,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: downloadAndroidApk,
              icon: const Icon(Icons.android_rounded),
              label: Text(text.downloadApk),
            ),
          ],
        ),
      ),
    );
  }
}
