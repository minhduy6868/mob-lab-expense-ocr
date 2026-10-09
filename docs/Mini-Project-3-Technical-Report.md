# BÁO CÁO KỸ THUẬT MINI-PROJECT #3

**Học phần:** Phát triển ứng dụng di động đa nền tảng  
**Đề tài:** VKU Ledger, quét hóa đơn và sổ chi theo tài khoản  
**Đơn vị:** Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU), Đại học Đà Nẵng  
**Khoa:** Khoa Khoa học Máy tính  
**Giảng viên hướng dẫn:** TS. Nguyễn Thanh Tuấn  
**Sinh viên:** Nguyễn Minh Duy, MSSV 23IT038, lớp 23IT  
**Năm:** 2026  
**Mã nguồn:** https://github.com/minhduy6868/mob-lab-expense-ocr  
**Bản chạy:** https://vku-expense-ocr.pages.dev  

## 1. Đặt vấn đề

Sinh viên và cán bộ lớp ở VKU thường giữ hóa đơn cà phê, photo, căn tin, xăng và vật tư câu lạc bộ. Gõ lại từng số vào bảng tính vừa chậm vừa dễ nhầm dấu phân cách của tiền Việt Nam.

Đồ án xây dựng **VKU Ledger**: một ứng dụng Flutter chạy trên Android, iOS và trình duyệt. Người dùng đăng ký tài khoản, chụp hóa đơn, đọc chữ trên ảnh, kiểm tra lại số tiền rồi lưu vào sổ của đúng tài khoản đó. Sổ nằm trên Cloudflare D1. Máy mất mạng vẫn giữ bản cục bộ và đẩy lên khi có mạng.

## 2. Mục tiêu và phạm vi

Mục tiêu của đồ án:

1. Đọc chữ trên ảnh hóa đơn ngay trên thiết bị, và trên web khi không có ML Kit.
2. Bóc tổng tiền, ngày và tên cửa hàng với hóa đơn viết tiếng Việt.
3. Cho người dùng sửa kết quả trước khi ghi sổ.
4. Mỗi tài khoản chỉ đọc và ghi dòng của mình.
5. Vẽ cơ cấu danh mục và chi tiêu trong tuần bằng Canvas.
6. Giao diện sáng, tối, tiếng Việt và tiếng Anh.

Ngoài phạm vi: không lưu ảnh hóa đơn lên đám mây, không bóc từng dòng mặt hàng, không thay thế phần mềm kế toán.

## 3. Công nghệ sử dụng

| Lớp | Công nghệ | Vai trò trong đồ án |
|---|---|---|
| Ứng dụng | Flutter 3.32, Dart 3.8, Impeller | Một mã nguồn cho Android, iOS và web. Impeller vẽ giao diện trên GPU. |
| Trạng thái | Riverpod 3 (`Notifier`, `AsyncNotifier`) | Sổ chi, bộ lọc, phiên đăng nhập và ngôn ngữ. |
| Điều hướng | GoRouter 17, `ShellRoute` | Thanh điều hướng cố định. Chưa đăng nhập thì về màn hình đăng nhập. |
| OCR di động | Google ML Kit Text Recognition | Đọc chữ Latin trên máy, không gửi ảnh đi. |
| OCR web | Tesseract.js 5.1.1, worker `vie+eng` | Đọc chữ trên trình duyệt vì ML Kit không chạy web. |
| Bóc tách | `ReceiptParser`, biểu thức chính quy nhiều lượt | Tổng tiền, ngày, cửa hàng, danh mục. |
| Máy | SQLite (`sqflite`), `shared_preferences` | Bản cục bộ và hàng đợi đồng bộ. Web dùng preferences. |
| Mây | Cloudflare D1 và Pages Functions | SQLite ở biên, API cùng tên miền với web app. |
| Tài khoản | Web Crypto SHA-256, salt ngẫu nhiên, token phiên 32 byte | Mật khẩu không lưu dạng thô. Mỗi request sổ chi gửi `Authorization: Bearer`. |
| Ảnh | `image_picker`, `path_provider` | Chụp hoặc chọn ảnh, giữ file trên máy. |
| Đồ họa | `CustomPainter`, `AnimationController` | Biểu đồ vành khăn và cột tuần. |
| Giao diện | Material 3, Inter, kính mờ `BackdropFilter` | Navy VKU, vàng cho nút quét. |
| Sáng tối | `ThemeMode` lưu trong `shared_preferences` | Theo hệ thống, luôn sáng, hoặc luôn tối. |
| Ngôn ngữ | `flutter_localizations`, `AppText`, `intl` | Tiếng Việt mặc định, chuyển tiếng Anh trên mọi màn. |
| Splash | `SplashScreen`, logo, fade 420 ms | Nền `#102343`. Hết splash thì vào sổ hoặc màn đăng nhập. |
| Web | PWA, `beforeinstallprompt` | Thêm ứng dụng ra màn hình chính. |
| Native | `MethodChannel` `vn.edu.vku/device_info` | Đọc pin thật từ `BatteryManager` trên Android. |

## 4. Kiến trúc

Hệ thống chia bốn tầng. Tầng trên không gọi thẳng D1. Mọi ghi đọc đi qua `DatabaseHelper`.

```
Người dùng
    |
Giao diện: sổ chi, quét, kiểm tra, báo cáo, đăng nhập, hệ thống
    |
Trạng thái: Riverpod (sổ, phiên, bộ lọc, ngôn ngữ, theme)
    |
Nghiệp vụ: ReceiptParser, mô hình ExpenseItem / ParsedReceipt
    |
Dữ liệu: SQLite hoặc cache web  <->  HTTP  <->  Pages Function  <->  D1
```

API nằm ở `functions/api/[[path]].js`.

| Phương thức | Đường dẫn | Việc làm |
|---|---|---|
| GET | `/api/health` | Kiểm tra binding D1. |
| POST | `/api/auth/register` | Tạo user, hash mật khẩu, mở phiên. Sổ mới trống. |
| POST | `/api/auth/login` | Đối chiếu hash, mở phiên. |
| GET | `/api/auth/me` | Đọc user của token. |
| POST | `/api/auth/logout` | Xóa phiên. |
| GET | `/api/expenses` | Liệt kê dòng của user đang đăng nhập. |
| POST | `/api/expenses/sync` | Nhận lô `upsert`, `delete`, `clear` rồi trả sổ mới. |

Cột `device_id` của bảng `expenses` lưu **id tài khoản**, không lưu id máy. Truy vấn luôn có `WHERE device_id = ?` với id lấy từ phiên. Đổi tài khoản trên cùng một máy sẽ xóa sổ cục bộ trước khi kéo sổ mới, nên hóa đơn của người trước không bị đẩy sang người sau.

## 5. Luồng quét hóa đơn

1. Người dùng chụp hoặc chọn ảnh.
2. Android và iOS đưa ảnh vào ML Kit. Web đưa byte ảnh vào Tesseract.js.
3. Nếu không đọc được chữ, ứng dụng báo lỗi. Không thay bằng hóa đơn mẫu.
4. `ReceiptParser` chạy nhiều lượt: ưu tiên dòng "tổng cộng" và "thanh toán", rồi "tổng tiền" và "tiền hàng", rồi cụm số đi với `đ`, `vnd`, `vnđ`.
5. Ngày nhận cả `dd/MM/yyyy` và `yyyy-MM-dd`.
6. Từ điển cửa hàng (Highlands, Co.op Mart, WinMart, Petrolimex, Long Châu, Fahasa và các tên khác) gán danh mục.
7. Màn hình kiểm tra hiện form. Người dùng sửa rồi mới ghi.
8. Bản ghi vào SQLite hoặc cache, sau đó vào hàng đợi. Khi có mạng, client gửi `POST /api/expenses/sync`.

Ảnh chỉ ở trên máy. D1 giữ chữ đã đọc, số tiền, danh mục và ghi chú.

### Bảng tinh chỉnh cho hóa đơn Việt Nam

| Trường | Cách bắt | Ghi chú |
|---|---|---|
| Tổng tiền, ưu tiên 1 | `tổng cộng`, `thanh toán`, `total`, `amount due` | Dòng kết của hóa đơn. |
| Tổng tiền, ưu tiên 2 | `tổng tiền`, `tiền hàng`, `cộng tiền`, `tiền mặt` | Dùng khi không có dòng tổng cộng. |
| Cụm số | `1.234`, `1,234`, `150000` | Cả dấu chấm và dấu phẩy ngăn nghìn. |
| Đơn vị | số đứng cạnh `đ`, `vnd`, `vnđ`, `d` | Quét từ dưới lên. |
| Ngày | `dd/MM/yyyy` và `yyyy-MM-dd` | Năm trong khoảng 2000. |
| Cửa hàng | Từ điển thương hiệu, rồi 4 dòng đầu không chứa từ rác | Gán luôn danh mục. |

Kiểm thử đơn vị trong `test/receipt_parser_test.dart` phủ Highlands Coffee (122.040 đ, ngày 22/10/2026), Co.op Mart và các dạng dấu chấm, dấu phẩy.

## 6. Tài khoản và đồng bộ

Đăng ký nhận tên `^[a-z0-9_]{3,24}$` và mật khẩu từ 6 đến 72 ký tự. Server tạo salt 16 byte, tính `SHA-256(salt + ":" + mật khẩu)` bằng Web Crypto, lưu hash. Phiên là 32 byte hex. Client giữ token trong `shared_preferences` và gắn header `Authorization`.

Sai mật khẩu trả `invalid_login`. Hết phiên trả `401`. Client xóa token khi nhận 401.

Đồng bộ theo lô thao tác, tối đa 200 thao tác một lần. Mất mạng thì hàng đợi nằm trên máy. Lần mở sau, nếu hàng đợi còn thì đẩy lên. Tài khoản mới không nhận dữ liệu mẫu và không nhận bản sao sổ của máy.

Ba bảng trên D1: `users`, `sessions`, `expenses`. Khóa chính của khoản chi là `(device_id, id)`.

## 7. Giao diện, ngôn ngữ, splash và native

Mở app, `SplashScreen` hiện logo trên nền `#102343`, dòng "VKU ĐÀ NẴNG" màu vàng và tên VKU Ledger. Logo mờ dần trong 420 ms. Nếu máy tắt animation thì splash hiện ngay. Router giữ người dùng ở splash khi chưa biết phiên, rồi chuyển tới sổ chi nếu đã đăng nhập, hoặc tới đăng nhập nếu chưa.

Ngôn ngữ mặc định là tiếng Việt. `AppText` và `AppTextDelegate` đi cùng `flutter_localizations`. Nút VI/EN có trên đăng nhập và trong Hệ thống. Chuỗi nút, lỗi đăng nhập, sổ chi và hộp thoại đều đổi theo locale đã lưu (`vku_locale`).

Sáng tối có ba mức: theo hệ thống, luôn sáng, luôn tối. Lựa chọn lưu local và áp lại lần mở sau. Sáng dùng navy cho nút chính. Tối dùng chữ kem trên mặt kính đậm, viền vàng mảnh, nút quét vẫn là vàng. Cùng một `ThemeData` cho mọi màn, không chỉnh màu rời từng chỗ.

Thanh dưới là dock kính, nút chính là **Quét hóa đơn**. Sổ chi có tổng tháng, tìm kiếm, lọc danh mục và vuốt để xóa. Báo cáo vẽ vành khăn theo danh mục và cột bảy ngày bằng `CustomPainter`. Nút **Đăng xuất** nằm trên sổ chi và trong Hệ thống.

`MethodChannel` tên `vn.edu.vku/device_info` gọi `getBatteryLevel`. Android trả dung lượng pin từ `BatteryManager`. Web và giả lập hiện mức mô phỏng. Web còn có thẻ cài ứng dụng qua `beforeinstallprompt`.

## 8. Đối chiếu yêu cầu đồ án

| Hạng mục | Minh chứng trong mã |
|---|---|
| OCR và heuristic | `ocr_service.dart`, `web_ocr.dart`, `receipt_parser.dart`, form kiểm tra trước khi lưu. |
| Canvas | `animated_donut_chart.dart`, `weekly_bar_chart_painter.dart`. |
| Trạng thái và dữ liệu | Riverpod 3, SQLite, hàng đợi đồng bộ, D1 theo user. |
| Giao diện | Material 3, sáng/tối/theo hệ thống, splash, form có validator, đa ngôn ngữ Việt-Anh. |
| Native | `platform_service.dart` và `MainActivity.kt`. |
| Tài liệu | Báo cáo này, README, kho Git, bản web đang chạy. |

## 9. Kiểm thử

- `flutter test test/receipt_parser_test.dart`: các ca hóa đơn mẫu và định dạng tiền.
- `flutter analyze` trên các file vừa sửa: không có cảnh báo.
- Thử API production với hai tài khoản: user A ghi một khoản, user B nhận danh sách rỗng, đăng nhập lại A vẫn thấy đúng khoản của A. Sai mật khẩu và request không token đều bị từ chối. Hai tài khoản thử đã được xóa sau khi kiểm tra.

## 10. Kết luận

VKU Ledger ghép OCR trên thiết bị, parser hóa đơn Việt Nam, sổ SQLite ngoại tuyến và Cloudflare D1 có tài khoản riêng. Người dùng đăng ký, đăng nhập, quét, sửa và chỉ thấy chi tiêu của mình. Bản web đang phục vụ tại https://vku-expense-ocr.pages.dev.

Đà Nẵng, tháng 10 năm 2026

**Sinh viên thực hiện**  
Nguyễn Minh Duy  
MSSV 23IT038
