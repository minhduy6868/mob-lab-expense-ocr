import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_text.dart';
import '../state/auth_controller.dart';

class LogoutButton extends ConsumerWidget {
  final bool wide;

  const LogoutButton({super.key, this.wide = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error.withValues(alpha: 0.72)),
        minimumSize: Size(wide ? double.infinity : 0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        visualDensity: wide ? VisualDensity.standard : VisualDensity.compact,
      ),
      onPressed: () => _confirm(context, ref),
      icon: const Icon(Icons.logout_rounded),
      label: Text(text.logOut),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(text.confirmLogout),
        content: Text(text.confirmLogoutBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(text.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(text.logOut),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
