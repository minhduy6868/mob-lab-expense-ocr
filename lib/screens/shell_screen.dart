import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../widgets/liquid_glass.dart';

/// ShellScreen provides the modern Floating Glassmorphic Dock Navigation Bar
class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dash')) return 0;
    if (location.startsWith('/reports')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dash');
        break;
      case 1:
        context.go('/reports');
        break;
      case 2:
        context.go('/scan');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIdx = _calculateSelectedIndex(context);
    final text = AppText.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main nested screen content (with bottom padding for floating bar)
          Positioned.fill(
            bottom: 74,
            child: child,
          ),

          // Floating Glassmorphic Island Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: GlassSurface(
                  radius: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        selectedIndex: selectedIdx,
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet_rounded,
                        label: text.ledger,
                        theme: theme,
                        onTap: () => _onItemTapped(0, context),
                      ),
                      _buildNavItem(
                        index: 1,
                        selectedIndex: selectedIdx,
                        icon: Icons.pie_chart_outline_rounded,
                        activeIcon: Icons.pie_chart_rounded,
                        label: text.reports,
                        theme: theme,
                        onTap: () => _onItemTapped(1, context),
                      ),
                      _buildCenterScanButton(
                        isSelected: selectedIdx == 2,
                        theme: theme,
                        label: text.scan,
                        onTap: () => _onItemTapped(2, context),
                      ),
                      _buildNavItem(
                        index: 3,
                        selectedIndex: selectedIdx,
                        icon: Icons.tune_rounded,
                        activeIcon: Icons.tune_rounded,
                        label: text.settings,
                        theme: theme,
                        onTap: () => _onItemTapped(3, context),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int selectedIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;
    final primaryColor = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScanButton({
    required bool isSelected,
    required ThemeData theme,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.navy, width: 1.4) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.document_scanner_rounded, color: AppColors.navy, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
