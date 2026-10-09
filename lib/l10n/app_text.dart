import 'package:flutter/widgets.dart';

class AppText {
  final Locale locale;

  const AppText(this.locale);

  bool get en => locale.languageCode == 'en';

  String pick(String vi, String english) => en ? english : vi;

  String get appSubtitle => pick('Sổ chi tiêu hóa đơn', 'Receipt expense ledger');
  String get logIn => pick('Đăng nhập', 'Log in');
  String get createAccount => pick('Tạo tài khoản', 'Create account');
  String get username => pick('Tên đăng nhập', 'Username');
  String get password => pick('Mật khẩu', 'Password');
  String get showPassword => pick('Hiện mật khẩu', 'Show password');
  String get hidePassword => pick('Ẩn mật khẩu', 'Hide password');
  String get loginHint => pick(
        'Dùng 3 đến 24 ký tự: chữ thường, số, gạch dưới.',
        'Use 3 to 24 characters: letters, numbers, underscore.',
      );
  String get needAccount => pick('Chưa có tài khoản?', 'Need an account?');
  String get haveAccount => pick('Đã có tài khoản?', 'Already have an account?');
  String get usernameInvalid => pick(
        'Tên đăng nhập cần 3 đến 24 ký tự, không dấu.',
        'Usernames need 3 to 24 letters, numbers, or underscores.',
      );
  String get passwordShort => pick('Mật khẩu cần ít nhất 6 ký tự.', 'Use at least 6 characters.');
  String get invalidLogin => pick('Sai tên đăng nhập hoặc mật khẩu.', 'Wrong username or password.');
  String get usernameTaken => pick('Tên này đã có người dùng.', 'That username is taken.');
  String get authFailed => pick('Không đăng nhập được. Thử lại.', 'Could not sign in. Try again.');
  String get authOffline => pick('Cần mạng để đăng nhập lần đầu.', 'A network connection is needed to sign in.');

  String authError(String code) => switch (code) {
        'invalid_username' => usernameInvalid,
        'weak_password' => passwordShort,
        'invalid_login' || 'unauthorized' => invalidLogin,
        'username_taken' => usernameTaken,
        'api_missing' => authOffline,
        _ => authFailed,
      };

  String get logOut => pick('Đăng xuất', 'Log out');
  String get signedInAs => pick('Đang dùng tài khoản', 'Signed in as');
  String get language => pick('Ngôn ngữ', 'Language');
  String get vietnamese => 'Tiếng Việt';
  String get english => 'English';

  String get ledger => pick('Sổ chi', 'Ledger');
  String get reports => pick('Báo cáo', 'Reports');
  String get scan => pick('Quét', 'Scan');
  String get settings => pick('Hệ thống', 'Settings');
  String get thisMonth => pick('Tổng chi tiêu tháng này', 'Spent this month');
  String get filtered => pick('Kết quả đang lọc', 'Filtered results');
  String thisWeek(String amount) => pick('Tuần này $amount', 'This week $amount');
  String get searchHint => pick('Tìm cửa hàng hoặc ghi chú', 'Search a shop or a note');
  String get emptyLedger => pick('Sổ chi đang trống', 'The ledger is empty');
  String get emptyFilter => pick('Không thấy khoản nào', 'No matching expenses');
  String get emptyFilterBody => pick('Thử từ khóa khác, hoặc xóa bộ lọc.', 'Try another word, or clear the filter.');
  String get emptyLedgerBody => pick('Quét một hóa đơn để ghi khoản chi đầu tiên.', 'Scan a receipt to add the first expense.');
  String get scanReceipt => pick('Quét hóa đơn', 'Scan a receipt');
  String get manualEntry => pick('Nhập tay', 'Enter manually');
  String get charts => pick('Biểu đồ', 'Charts');
  String get loadSamples => pick('Nạp mẫu', 'Load samples');
  String get samplesLoaded => pick('Đã nạp 7 hóa đơn mẫu.', 'Loaded 7 sample receipts.');

  String get syncing => pick('Đang kết nối Cloudflare D1', 'Connecting to Cloudflare D1');
  String get synced => pick('Đã đồng bộ Cloudflare D1', 'Synced with Cloudflare D1');
  String get offline => pick('Ngoại tuyến. Dữ liệu giữ trên máy.', 'Offline. The copy on this device is kept.');

  String get installTitle => pick('Cài VKU Ledger', 'Install VKU Ledger');
  String get installBody => pick(
        'Thêm vào màn hình chính, hoặc tải file APK cho Android.',
        'Add it to the home screen, or download the Android APK.',
      );
  String get addToHome => pick('Thêm vào màn hình chính', 'Add to home screen');
  String get downloadApk => pick('Tải APK Android', 'Download Android APK');
  String get installHelp => pick(
        'Nếu nút không mở được, dùng menu trình duyệt rồi chọn Cài đặt ứng dụng.',
        'If the button does nothing, open the browser menu and choose Install app.',
      );

  String get themeTitle => pick('Giao diện', 'Appearance');
  String get themeSystem => pick('Tự động', 'System');
  String get themeLight => pick('Sáng', 'Light');
  String get themeDark => pick('Tối', 'Dark');
  String get cloudTitle => pick('Cloudflare D1', 'Cloudflare D1');
  String cloudBody(String device) => pick(
        'Thiết bị $device. Ảnh hóa đơn vẫn nằm trên máy.',
        'Device $device. Receipt photos stay on this device.',
      );
  String get syncNow => pick('Đồng bộ ngay', 'Sync now');
  String get syncNowBody => pick('Đẩy sổ trên máy lên Cloudflare D1 và kéo bản mới nhất', 'Send this device copy to Cloudflare D1 and pull the latest');
  String get seedSamples => pick('Nạp lại 7 hóa đơn mẫu', 'Reload 7 sample receipts');
  String get seedSamplesBody => pick(
        'Highlands, Co.op Mart, Petrolimex và các mẫu còn lại.',
        'Highlands, Co.op Mart, Petrolimex, and the rest.',
      );
  String get clearLedger => pick('Xóa sạch sổ chi', 'Erase the ledger');
  String get clearLedgerBody => pick('Xóa trên máy và trên Cloudflare D1', 'Deletes the copy on this device and on Cloudflare D1');

  String get byCategory => pick('Danh mục', 'Categories');
  String get weekTab => pick('Tuần này', 'This week');
  String get scanTitle => pick('Quét hóa đơn', 'Scan a receipt');
  String get reviewTitle => pick('Kiểm tra hóa đơn', 'Check the receipt');
  String get editTitle => pick('Sửa khoản chi', 'Edit expense');
  String get saveLedger => pick('Lưu vào sổ chi', 'Save to the ledger');
  String get saveChanges => pick('Lưu thay đổi', 'Save changes');
  String get saved => pick('Đã lưu khoản chi.', 'Expense saved.');
  String get updated => pick('Đã cập nhật khoản chi.', 'Expense updated.');
  String get detailTitle => pick('Hóa đơn', 'Receipt');
  String get missingExpense => pick('Không thấy khoản chi này.', 'This expense is gone.');
  String get confirmLogout => pick('Đăng xuất khỏi sổ chi?', 'Log out of this ledger?');
  String get confirmLogoutBody => pick(
        'Sổ trên máy này sẽ được gỡ khỏi ứng dụng. Bản trên tài khoản vẫn giữ.',
        'This device copy is cleared. The account copy stays.',
      );
  String get cancel => pick('Hủy', 'Cancel');
  String get confirmErase => pick('Xác nhận xóa sạch', 'Erase the ledger?');
  String get confirmEraseBody => pick('Thao tác này xóa mọi hóa đơn đã lưu.', 'This deletes every saved receipt.');
  String get erase => pick('Xóa sạch', 'Erase');
  String get erased => pick('Đã dọn sổ chi.', 'Ledger cleared.');
  String get samplesReloaded => pick('Đã nạp lại 7 hóa đơn mẫu.', 'Reloaded 7 sample receipts.');
  String get pasteOcr => pick('Dán văn bản OCR', 'Paste OCR text');
  String get save => pick('Lưu', 'Save');
  String get copiedOcr => pick('Đã sao chép văn bản OCR.', 'OCR text copied.');
  String get copy => pick('Sao chép', 'Copy');
  String get readingReceipt => pick('Đang đọc chữ trên hóa đơn...', 'Reading the receipt...');
  String get ocrBanner => pick('Đọc chữ trên hóa đơn', 'Read the receipt');
  String get ocrBannerBody => pick(
        'Tên quán, số tiền và ngày lấy từ chữ trên ảnh.',
        'Shop, amount, and date come from the text on the photo.',
      );
  String get sampleSection => pick('Mẫu để thử', 'Sample receipts');
  String get sampleSectionBody => pick(
        'Các thẻ dưới đây là hóa đơn giả lập, không phải ảnh vừa chụp.',
        'The cards below are fake receipts, not the photo you just took.',
      );
  String get cannotReadImage => pick(
        'Không đọc được ảnh. Chụp lại hoặc chọn ảnh khác.',
        'Could not read that photo. Take another or pick a different one.',
      );
  String get pasteReceipt => pick('Dán văn bản hóa đơn', 'Paste receipt text');
  String get readReceipt => pick('Đọc hóa đơn', 'Read receipt');
  String get takePhoto => pick('Chụp máy ảnh', 'Take a photo');
  String get pickImage => pick('Chọn ảnh', 'Choose a photo');

  static AppText of(BuildContext context) {
    return Localizations.of<AppText>(context, AppText) ?? const AppText(Locale('vi'));
  }
}

class AppTextDelegate extends LocalizationsDelegate<AppText> {
  const AppTextDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'vi' || locale.languageCode == 'en';

  @override
  Future<AppText> load(Locale locale) async => AppText(locale);

  @override
  bool shouldReload(covariant AppTextDelegate old) => false;
}
