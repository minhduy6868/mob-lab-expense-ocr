import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_text.dart';
import '../services/database_helper.dart';
import '../services/platform_service.dart';
import '../state/auth_controller.dart';
import '../state/expense_providers.dart';
import '../widgets/install_app_card.dart';
import '../widgets/language_picker.dart';
import '../widgets/vku_logo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _batteryLevel;
  bool _isLoadingBattery = false;

  @override
  void initState() {
    super.initState();
    _checkBattery();
  }

  String _syncLabel(AppText text, CloudSyncPhase phase) {
    return switch (phase) {
      CloudSyncPhase.synced => text.synced,
      CloudSyncPhase.offline => text.offline,
      CloudSyncPhase.checking => text.syncing,
    };
  }

  Future<void> _checkBattery() async {
    setState(() => _isLoadingBattery = true);
    final level = await PlatformService.getBatteryLevel();
    if (mounted) {
      setState(() {
        _batteryLevel = level;
        _isLoadingBattery = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final sync = ref.watch(cloudSyncProvider);
    final auth = ref.watch(authProvider);
    final db = DatabaseHelper.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.settings),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Card(
              elevation: 0.8,
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
                              Text(
                                'VKU Ledger',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text('${text.signedInAs} ${auth.username}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const LanguagePicker(),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(text.confirmLogout),
                            content: Text(text.confirmLogoutBody),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(text.cancel)),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(text.logOut)),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authProvider.notifier).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(text.logOut),
                    ),
                  ],
                ),
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 12),
              const InstallAppCard(),
            ],
            const SizedBox(height: 12),
            // Theme Mode Section
            Card(
              elevation: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.palette_rounded, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          text.themeTitle,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_rounded),
                          label: Text(text.themeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_rounded),
                          label: Text(text.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_rounded),
                          label: Text(text.themeDark),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Platform Channels Native Interop Card (Slide 37-39)
            Card(
              elevation: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.battery_charging_full_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Native MethodChannel',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '"vn.edu.vku/device_info"',
                                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          onPressed: _checkBattery,
                          tooltip: 'Đo lại pin thiết bị',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingBattery)
                      const LinearProgressIndicator()
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _batteryLevel != null && _batteryLevel! >= 0
                                ? 'Pin thiết bị thật (Android Kotlin / iOS):'
                                : 'Môi trường mô phỏng (Simulator/Web):',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _batteryLevel != null && _batteryLevel! >= 0
                                ? '$_batteryLevel%'
                                : '88% (Giả lập)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_batteryLevel != null && _batteryLevel! >= 0)
                              ? _batteryLevel! / 100.0
                              : 0.88,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          color: const Color(0xFF10B981),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0.8,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_done_rounded, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(text.cloudTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_syncLabel(text, sync.phase)}\n${text.cloudBody(db.deviceLabel)}'),
                    isThreeLine: true,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sync_rounded),
                    title: Text(text.syncNow),
                    subtitle: Text(text.syncNowBody),
                    onTap: () async {
                      await ref.read(expenseListProvider.notifier).refreshFromCloud();
                      if (context.mounted) {
                        final phase = DatabaseHelper.instance.lastStatus.phase;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_syncLabel(AppText.of(context), phase))),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: Text(text.seedSamples),
                    subtitle: Text(text.seedSamplesBody),
                    onTap: () async {
                      await ref.read(expenseListProvider.notifier).seedSampleData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(text.samplesReloaded)),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
                    title: Text(
                      text.clearLedger,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: Text(text.clearLedgerBody),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(text.confirmErase),
                          content: Text(text.confirmEraseBody),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(text.cancel)),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                              child: Text(text.erase),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(expenseListProvider.notifier).clearAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(text.erased)),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Academic & Project Info Card
            Card(
              elevation: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFFDC2626), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Đồ án Mini-Project #3 (Tuần 7 - 8)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Học phần: Phát triển ứng dụng di động đa nền tảng'),
                    const Text('Khoa: Khoa Khoa học Máy tính - VKU Đà Nẵng'),
                    const Text('Giảng viên hướng dẫn: TS. Nguyễn Thanh Tuấn'),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        const Text(
                          'Live Web Demo: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'vku-expense-ocr.pages.dev',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
