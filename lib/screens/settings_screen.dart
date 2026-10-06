import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/platform_service.dart';
import '../state/expense_providers.dart';

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
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt & Hệ Thống'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                        Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Giao diện Material Design 3',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('Tự động'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Sáng'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Tối'),
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
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.battery_charging_full_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text(
                  'MethodChannel ("vn.edu.vku/device_info")',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  _isLoadingBattery
                      ? 'Đang gọi Native Kotlin/Swift...'
                      : (_batteryLevel != null && _batteryLevel! >= 0
                          ? 'Dung lượng pin thiết bị: $_batteryLevel%'
                          : 'Thiết bị mô phỏng / Không phản hồi pin'),
                  style: TextStyle(
                    color: (_batteryLevel != null && _batteryLevel! >= 0)
                        ? Colors.green.shade700
                        : theme.colorScheme.outline,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _checkBattery,
                  tooltip: 'Kiểm tra lại Native Channel',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // SQLite Database Management Card
            Card(
              elevation: 0.8,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: const Icon(Icons.storage_rounded, color: Colors.blue),
                    ),
                    title: const Text('Cơ sở dữ liệu SQLite (sqflite)'),
                    subtitle: const Text('Quản lý lưu trữ ngoại tuyến cục bộ'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: const Text('Nạp lại dữ liệu mẫu VKU'),
                    subtitle: const Text('Khôi phục danh sách hóa đơn Highlands, Co.op Mart...'),
                    onTap: () async {
                      await ref.read(expenseListProvider.notifier).seedSampleData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(' Đã nạp lại dữ liệu mẫu thành công!')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
                    title: Text(
                      'Xóa sạch toàn bộ dữ liệu',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Xóa toàn bộ các bảng trong SQLite'),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận xóa sạch'),
                          content: const Text('Thao tác này sẽ xóa vĩnh viễn tất cả hóa đơn đã lưu.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                              child: const Text('Xóa sạch'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(expenseListProvider.notifier).clearAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã dọn dẹp cơ sở dữ liệu!')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Project & Academic Info Card
            Card(
              elevation: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin đồ án Mini-Project #3',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Học phần: Phát triển ứng dụng di động đa nền tảng'),
                    const Text('Đơn vị: Trường ĐH CNTT & TT Việt - Hàn (VKU)'),
                    const Text('Giảng viên hướng dẫn: TS. Nguyễn Thanh Tuấn'),
                    const Text('Thời lượng: Tuần 7 - 8 (Trọng số: 10%)'),
                    const Divider(height: 20),
                    const Text(
                      'Công nghệ cốt lõi: Flutter 3.x, Dart 3 (Records, Pattern Matching), Google ML Kit Text Recognition, SQLite sqflite, Riverpod 2 Notifier, CustomPainter Animated Donut & Bar Charts.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
