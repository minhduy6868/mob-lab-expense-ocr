import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/parsed_receipt.dart';
import '../services/ocr_service.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  bool _isProcessing = false;
  String _statusMessage = '';

  Future<void> _processFromSource(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = source == ImageSource.camera
          ? 'Đang mở máy ảnh & chụp hóa đơn...'
          : 'Đang tải ảnh từ thư viện...';
    });

    try {
      final parsed = await OcrService.instance.processFromImageSource(source);
      if (!mounted) return;

      if (parsed != null) {
        setState(() {
          _statusMessage = 'Đang phân tích OCR & Regex Heuristics...';
        });
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        _navigateToReview(parsed);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể quét ảnh: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _processSampleReceipt(String name, String sampleText) {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang phân tích mẫu $name...';
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final parsed = OcrService.instance.parseFromRawText(sampleText);
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _navigateToReview(parsed);
    });
  }

  void _navigateToReview(ParsedReceipt parsed) {
    context.push('/review', extra: parsed);
  }

  void _openManualTextInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập nội dung hóa đơn thủ công'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: textController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Dán toàn bộ văn bản hóa đơn (OCR raw text) vào đây...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final raw = textController.text.trim();
              if (raw.isNotEmpty) {
                Navigator.pop(ctx);
                final parsed = OcrService.instance.parseFromRawText(raw);
                _navigateToReview(parsed);
              }
            },
            child: const Text('Phân tích'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn (OCR ML Kit)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: 'Nhập văn bản hóa đơn',
            onPressed: _openManualTextInputDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera / Viewfinder illustrative card
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Google ML Kit On-Device OCR',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trích xuất tự động Tên quán, Tổng tiền, Ngày tháng',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scan Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _processFromSource(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Chụp ảnh'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _isProcessing
                              ? null
                              : () => _processFromSource(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Chọn ảnh'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            foregroundColor: theme.colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Preloaded Vietnamese Sample Receipts Section
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Thử nghiệm mẫu hóa đơn Việt Nam',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kiểm thử thuật toán Regex Heuristics đa dạng định dạng (VNĐ, đ, dấu chấm/phẩy)',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 12),

                  _buildSampleCard(
                    title: 'Highlands Coffee',
                    subtitle: 'Tổng cộng: 122.040 đ • Ngày 22/10/2026',
                    icon: Icons.coffee_rounded,
                    color: Colors.brown,
                    onTap: () => _processSampleReceipt('Highlands Coffee', _sampleHighlands),
                  ),
                  _buildSampleCard(
                    title: 'Co.op Mart Đà Nẵng',
                    subtitle: 'Thanh toán: 345.500 VNĐ • Ngày 20/10/2026',
                    icon: Icons.shopping_cart_rounded,
                    color: Colors.blue.shade700,
                    onTap: () => _processSampleReceipt('Co.op Mart', _sampleCoopMart),
                  ),
                  _buildSampleCard(
                    title: 'WinMart+ Cẩm Lệ',
                    subtitle: 'TỔNG TIỀN: 185,000 đ • Ngày 19/10/2026',
                    icon: Icons.store_rounded,
                    color: Colors.red.shade700,
                    onTap: () => _processSampleReceipt('WinMart', _sampleWinmart),
                  ),
                  _buildSampleCard(
                    title: 'Petrolimex Sông Hàn',
                    subtitle: 'Tổng tiền xăng: 80.000 đ • 18/10/2026',
                    icon: Icons.local_gas_station_rounded,
                    color: Colors.orange.shade800,
                    onTap: () => _processSampleReceipt('Petrolimex', _samplePetrolimex),
                  ),
                  _buildSampleCard(
                    title: 'Nhà Sách Fahasa',
                    subtitle: 'Cần thanh toán: 215.000 đ • 17/10/2026',
                    icon: Icons.menu_book_rounded,
                    color: Colors.teal.shade700,
                    onTap: () => _processSampleReceipt('Fahasa', _sampleFahasa),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isProcessing)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.8,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: _isProcessing ? null : onTap,
      ),
    );
  }

  static const _sampleHighlands = '''
HIGHLANDS COFFEE VKU
Khu đô thị Đại học Đà Nẵng, Hòa Quý, Ngũ Hành Sơn
ĐT: 0236 3667 113
HÓA ĐƠN THANH TOÁN
Số HD: HD-98421
Ngày: 22/10/2026 14:15
Thu ngân: Hoa_Tran

Phin Sữa Đá Size L         39.000
Trà Thạch Đào Size M       54.000
Bánh Phô Mai Cà Phê        29.000

Tiền hàng:                122.000
Thuế GTGT (0%):                 0
TỔNG CỘNG:               122.040 đ

Hình thức: Tiền mặt
Xin cảm ơn Quý khách!
''';

  static const _sampleCoopMart = '''
CO.OP MART DA NANG
478 Dien Bien Phu, Thanh Khe, Da Nang
HOA DON BAN LE
So: CP-089123
Ngay: 20/10/2026 18:40

Mi Hao Hao Sa Te (Thung)   118.000
Sua Tuoi Vinamilk 1L        36.500
Dau An Simply 1L            65.000
Thit Heo Ba Chi 500g       126.000

Cong tien hang:            345.500
THANH TOAN: 345.500 VNĐ
Giam gia hoi vien:               0
Khach dua:                 400.000
Tien tra lai:               54.500
''';

  static const _sampleWinmart = '''
WINMART+ CAM LE
123 Ong Ich Duong, Cam Le, Da Nang
PHIEU TINH TIEN
Ngay: 19/10/2026 11:20

Banh Mi Tuoi Kinh Do        15.000
Nuoc Ngot Coca Cola 1.5L    22.000
Xuc Xich Duc CP 500g        88.000
Khan Giay Pulppy            60.000

TỔNG TIỀN: 185,000 đ
Phuong thuc: The Ngan Hang
Cam on quy khach hen gap lai!
''';

  static const _samplePetrolimex = '''
PETROLIMEX CUA HANG XANG DAU SO 12
Duong Nam Ky Khoi Nghia, Da Nang
HOA DON XANG DAU
Ngay gio: 18/10/2026 07:45
Loai xang: RON 95-III
Don gia: 21.850 d/lit
So lit: 3.66 lit

TỔNG TIỀN: 80.000 đ
Thanh toan: Tien mat
''';

  static const _sampleFahasa = '''
NHA SACH FAHASA DA NANG
300 Le Duan, Da Nang
PHIEU THANH TOAN
Ngay: 17/10/2026 16:30

Giao Trinh Lap Trinh Flutter 3     135.000
So Tay Sinh Vien VKU                45.000
But Bi Pentel 0.5 (2 cay)           35.000

CẦN THANH TOÁN: 215.000 đ
Khach da thanh toan: 215.000
''';
}
