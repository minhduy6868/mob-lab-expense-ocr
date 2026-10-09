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

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String _statusMessage = '';
  late final AnimationController _laserController;
  late final CurvedAnimation _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    final reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduceMotion) {
      _laserController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _laserAnimation.dispose();
    _laserController.dispose();
    super.dispose();
  }

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
          _statusMessage = 'Google ML Kit đang nhận diện & bóc tách regex...';
        });
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        _navigateToReview(parsed);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đọc được ảnh. Chụp lại hoặc chọn ảnh khác.')),
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
      _statusMessage = 'Đang phân tích OCR mẫu: $name...';
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
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded),
            SizedBox(width: 8),
            Text('Dán văn bản hóa đơn'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: textController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Dán chữ trên hóa đơn vào đây',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.psychology_rounded, size: 18),
            onPressed: () {
              final raw = textController.text.trim();
              if (raw.isNotEmpty) {
                Navigator.pop(ctx);
                final parsed = OcrService.instance.parseFromRawText(raw);
                _navigateToReview(parsed);
              }
            },
            label: const Text('Đọc hóa đơn'),
          ),
        ],
      ),
    ).whenComplete(textController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: 'Dán văn bản OCR',
            onPressed: _openManualTextInputDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Animated Scanner Viewfinder Box
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F172A),
                          theme.colorScheme.primary.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Viewfinder Corner Brackets
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Stack(
                              children: [
                                // Top-Left
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                        left: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                                // Top-Right
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                        right: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                                // Bottom-Left
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                        left: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                                // Bottom-Right
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                        right: BorderSide(color: Color(0xFF38BDF8), width: 3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Animated Sweeping Laser Line
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, _) {
                            return Positioned(
                              top: 40 + (_laserAnimation.value * 140),
                              left: 36,
                              right: 36,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF38BDF8),
                                      Color(0xFF00E5FF),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 1.5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Center Viewfinder Info
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  size: 34,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Google ML Kit On-Device OCR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tự động bóc tách Tổng tiền, Tên quán, Ngày giao dịch',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Action Buttons (Camera / Gallery)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _processFromSource(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Chụp Máy Ảnh'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _processFromSource(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Chọn Tệp Ảnh'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Realistic Vietnamese Sample Receipts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on_rounded, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Thử Nghiệm Mẫu Hóa Đơn Việt Nam',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1-Tap Test',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kiểm thử thuật toán Regex đa định dạng (VNĐ, đ, dấu chấm/phẩy, không cần giấy in)',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 12),

                  _buildSampleCard(
                    title: 'Highlands Coffee VKU',
                    subtitle: '122.040 đ • Ngày 22/10/2026',
                    tag: 'Ăn uống',
                    icon: Icons.coffee_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () => _processSampleReceipt('Highlands Coffee', _sampleHighlands),
                  ),
                  _buildSampleCard(
                    title: 'Co.op Mart Đà Nẵng',
                    subtitle: '345.500 VNĐ • Ngày 20/10/2026',
                    tag: 'Siêu thị',
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () => _processSampleReceipt('Co.op Mart', _sampleCoopMart),
                  ),
                  _buildSampleCard(
                    title: 'WinMart+ Cẩm Lệ',
                    subtitle: '185,000 đ • Ngày 19/10/2026',
                    tag: 'Bách hóa',
                    icon: Icons.store_rounded,
                    color: const Color(0xFFDC2626),
                    onTap: () => _processSampleReceipt('WinMart', _sampleWinmart),
                  ),
                  _buildSampleCard(
                    title: 'Petrolimex Nam Kỳ Khởi Nghĩa',
                    subtitle: '80.000 đ • Ngày 18/10/2026',
                    tag: 'Đi lại',
                    icon: Icons.local_gas_station_rounded,
                    color: const Color(0xFFEA580C),
                    onTap: () => _processSampleReceipt('Petrolimex', _samplePetrolimex),
                  ),
                  _buildSampleCard(
                    title: 'Nhà Sách Fahasa Đà Nẵng',
                    subtitle: '215.000 đ • Ngày 17/10/2026',
                    tag: 'Học tập',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF0D9488),
                    onTap: () => _processSampleReceipt('Fahasa', _sampleFahasa),
                  ),
                ],
              ),
            ),

            // Loading overlay with pulsing spinner
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    elevation: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(strokeWidth: 3.5),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
    required String tag,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0.6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
        ),
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
