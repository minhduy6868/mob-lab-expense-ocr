"""
Báo cáo kỹ thuật Mini-Project 3, bản PDF 4 trang.
Sinh viên: Nguyễn Minh Duy, MSSV 23IT038.
"""

from __future__ import annotations
from pathlib import Path
from fpdf import FPDF
from fpdf.enums import XPos, YPos

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "Mini-Project-3-Technical-Report.pdf"
FONT = Path(r"C:\Windows\Fonts\arial.ttf")
FONT_B = Path(r"C:\Windows\Fonts\arialbd.ttf")
FONT_I = Path(r"C:\Windows\Fonts\ariali.ttf")


class ReportPDF(FPDF):
    def header(self) -> None:
        if self.page_no() == 1:
            return
        self.set_font("ArialVN", "I", 8)
        self.set_text_color(100, 116, 139)
        self.cell(
            0,
            5,
            "VKU Ledger  |  Báo cáo Mini-Project #3  |  Nguyễn Minh Duy (23IT038)",
            new_x=XPos.LMARGIN,
            new_y=YPos.NEXT,
        )
        self.set_draw_color(203, 213, 225)
        self.set_line_width(0.3)
        self.line(16, 11.5, 194, 11.5)
        self.ln(2)
        self.set_text_color(0, 0, 0)

    def footer(self) -> None:
        self.set_y(-12)
        self.set_font("ArialVN", "", 8)
        self.set_text_color(148, 163, 184)
        self.cell(0, 8, f"Trang {self.page_no()}  |  VKU, Phát triển ứng dụng di động đa nền tảng", align="C")
        self.set_text_color(0, 0, 0)

    def section_header(self, title: str) -> None:
        self.ln(2.2)
        self.set_fill_color(241, 245, 249)
        self.set_font("ArialVN", "B", 10)
        self.set_text_color(30, 58, 138)
        y = self.get_y()
        self.rect(16, y, 2.2, 6, style="F")
        self.set_xy(20, y)
        self.cell(0, 6, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1.2)
        self.set_text_color(0, 0, 0)

    def body_p(self, text: str) -> None:
        self.set_font("ArialVN", "", 9)
        self.set_text_color(30, 41, 59)
        self.multi_cell(0, 4.5, text)
        self.ln(0.8)

    def kv(self, key: str, val: str) -> None:
        self.set_font("ArialVN", "B", 9)
        self.set_text_color(30, 58, 138)
        self.cell(38, 5, f"{key}:")
        self.set_font("ArialVN", "", 9)
        self.set_text_color(15, 23, 42)
        self.cell(0, 5, val, new_x=XPos.LMARGIN, new_y=YPos.NEXT)


def draw_table(pdf: ReportPDF, headers: list[str], rows: list[list[str]], col_widths: list[float]) -> None:
    pdf.set_font("ArialVN", "B", 8)
    pdf.set_fill_color(30, 58, 138)
    pdf.set_text_color(255, 255, 255)
    pdf.set_draw_color(203, 213, 225)
    for header, width in zip(headers, col_widths):
        pdf.cell(width, 6, f" {header}", border=1, fill=True)
    pdf.ln(6)

    fill = False
    for row in rows:
        heights = []
        pdf.set_font("ArialVN", "", 8)
        for cell, width in zip(row, col_widths):
            lines = pdf.multi_cell(width - 2, 4.2, cell, dry_run=True, output="LINES")
            heights.append(max(1, len(lines)) * 4.2 + 1.6)
        row_h = max(heights)
        if pdf.get_y() + row_h > 275:
            pdf.add_page()
        x0 = pdf.get_x()
        y0 = pdf.get_y()
        pdf.set_fill_color(248, 250, 252) if fill else pdf.set_fill_color(255, 255, 255)
        x = x0
        for cell, width in zip(row, col_widths):
            pdf.rect(x, y0, width, row_h, style="DF")
            pdf.set_xy(x + 1, y0 + 0.8)
            pdf.set_text_color(30, 41, 59)
            pdf.multi_cell(width - 2, 4.2, cell)
            x += width
        pdf.set_xy(x0, y0 + row_h)
        fill = not fill
    pdf.ln(1.5)


def main() -> None:
    pdf = ReportPDF(orientation="P", unit="mm", format="A4")
    pdf.set_margins(16, 16, 16)
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_title("VKU Ledger - Bao cao ky thuat Mini-Project 3")
    pdf.set_author("Nguyen Minh Duy (23IT038)")
    pdf.set_subject("Quet hoa don, so chi theo tai khoan, Cloudflare D1")
    pdf.set_keywords("Flutter, ML Kit, Tesseract.js, Riverpod, Cloudflare D1, Nguyen Minh Duy, 23IT038")

    pdf.add_font("ArialVN", "", str(FONT))
    pdf.add_font("ArialVN", "B", str(FONT_B))
    pdf.add_font("ArialVN", "I", str(FONT_I))

    pdf.add_page()
    pdf.set_font("ArialVN", "B", 12)
    pdf.set_text_color(30, 58, 138)
    pdf.cell(0, 6, "TRƯỜNG ĐẠI HỌC CNTT VÀ TRUYỀN THÔNG VIỆT - HÀN", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("ArialVN", "", 9)
    pdf.set_text_color(71, 85, 105)
    pdf.cell(0, 5, "Khoa Khoa học Máy tính  •  Đại học Đà Nẵng", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(3)
    pdf.set_font("ArialVN", "B", 13)
    pdf.set_text_color(30, 58, 138)
    pdf.cell(0, 7, "BÁO CÁO KỸ THUẬT MINI-PROJECT #3", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("ArialVN", "", 10)
    pdf.set_text_color(15, 23, 42)
    pdf.cell(0, 6, "VKU Ledger: quét hóa đơn và sổ chi theo tài khoản", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(3)
    pdf.kv("Học phần", "Phát triển ứng dụng di động đa nền tảng")
    pdf.kv("Giảng viên", "TS. Nguyễn Thanh Tuấn")
    pdf.kv("Sinh viên", "Nguyễn Minh Duy    MSSV 23IT038    Lớp 23IT")
    pdf.kv("Mã nguồn", "github.com/minhduy6868/mob-lab-expense-ocr")
    pdf.kv("Bản chạy", "https://vku-expense-ocr.pages.dev")
    pdf.ln(1)

    pdf.section_header("1. Đặt vấn đề")
    pdf.body_p(
        "Sinh viên và cán bộ lớp ở VKU thường giữ hóa đơn cà phê, photo, căn tin, xăng và vật tư câu lạc bộ. "
        "Gõ lại từng số vào bảng tính vừa chậm vừa dễ nhầm dấu phân cách của tiền Việt Nam. "
        "Đồ án xây dựng VKU Ledger trên Flutter cho Android, iOS và trình duyệt. Người dùng đăng ký tài khoản, "
        "chụp hóa đơn, đọc chữ trên ảnh, kiểm tra số tiền rồi lưu vào sổ của đúng tài khoản đó. "
        "Sổ nằm trên Cloudflare D1. Máy mất mạng vẫn giữ bản cục bộ và đẩy lên khi có mạng."
    )

    pdf.section_header("2. Mục tiêu và phạm vi")
    pdf.body_p(
        "Đọc chữ trên ảnh hóa đơn trên máy và trên web. Bóc tổng tiền, ngày và tên cửa hàng. "
        "Cho người dùng sửa trước khi ghi sổ. Mỗi tài khoản chỉ đọc và ghi dòng của mình. "
        "Vẽ cơ cấu danh mục và chi tiêu tuần bằng Canvas. Giao diện sáng, tối, tiếng Việt và tiếng Anh. "
        "Ngoài phạm vi: không đưa ảnh hóa đơn lên mây, không bóc từng dòng mặt hàng, không thay phần mềm kế toán."
    )

    pdf.section_header("3. Công nghệ sử dụng")
    draw_table(
        pdf,
        ["Lớp", "Công nghệ", "Vai trò"],
        [
            ["Ứng dụng", "Flutter 3.32, Dart 3.8, Impeller", "Một mã cho Android, iOS và web. Vẽ trên GPU."],
            ["Trạng thái", "Riverpod 3", "Sổ chi, bộ lọc, phiên đăng nhập, ngôn ngữ."],
            ["Điều hướng", "GoRouter, ShellRoute", "Dock cố định. Chưa đăng nhập thì về màn hình đăng nhập."],
            ["OCR máy", "Google ML Kit", "Đọc chữ trên Android và iOS, không gửi ảnh đi."],
            ["OCR web", "Tesseract.js 5, vie+eng", "Đọc chữ trên trình duyệt khi không có ML Kit."],
            ["Bóc tách", "ReceiptParser", "Nhiều lượt regex cho tiền, ngày, cửa hàng, danh mục."],
            ["Máy", "SQLite, shared_preferences", "Bản cục bộ và hàng đợi đồng bộ."],
            ["Mây", "Cloudflare D1, Pages Functions", "SQLite ở biên, API cùng miền với web app."],
            ["Tài khoản", "Web Crypto SHA-256, salt, token", "Mật khẩu không lưu thô. Sổ chi cần Bearer token."],
            ["Đồ họa", "CustomPainter", "Biểu đồ vành khăn và cột bảy ngày."],
            ["Giao diện", "Material 3, kính mờ", "Navy VKU, vàng cho nút quét."],
            ["Sáng tối", "ThemeMode", "Theo hệ thống, luôn sáng, hoặc luôn tối. Lưu local."],
            ["Ngôn ngữ", "AppText, intl", "Tiếng Việt mặc định, chuyển tiếng Anh trên mọi màn."],
            ["Splash", "SplashScreen", "Nền #102343, logo, fade 420 ms, rồi vào sổ hoặc đăng nhập."],
            ["Native", "MethodChannel pin", "BatteryManager trên Android."],
        ],
        [32, 62, 84],
    )

    pdf.section_header("4. Kiến trúc và API")
    pdf.body_p(
        "Bốn tầng: giao diện, trạng thái Riverpod, nghiệp vụ ReceiptParser, rồi dữ liệu. "
        "Mọi ghi đọc đi qua DatabaseHelper. Client không gọi D1 trực tiếp. "
        "API ở functions/api/[[path]].js. Cột device_id của expenses lưu id tài khoản. "
        "Mọi truy vấn có WHERE device_id = id lấy từ phiên. Đổi tài khoản sẽ xóa sổ cục bộ trước khi kéo sổ mới."
    )
    draw_table(
        pdf,
        ["Phương thức", "Đường dẫn", "Việc làm"],
        [
            ["POST", "/api/auth/register", "Tạo user, hash mật khẩu, mở phiên. Sổ mới trống."],
            ["POST", "/api/auth/login", "Đối chiếu hash, mở phiên."],
            ["GET", "/api/auth/me", "Đọc user của token."],
            ["POST", "/api/auth/logout", "Xóa phiên."],
            ["GET", "/api/expenses", "Liệt kê dòng của user đang đăng nhập."],
            ["POST", "/api/expenses/sync", "Nhận upsert, delete, clear rồi trả sổ mới."],
        ],
        [28, 52, 98],
    )

    pdf.section_header("5. Luồng quét hóa đơn")
    pdf.body_p(
        "Người dùng chụp hoặc chọn ảnh. Android và iOS đưa ảnh vào ML Kit. Web đưa byte ảnh vào Tesseract.js. "
        "Nếu không đọc được chữ, ứng dụng báo lỗi và không thay bằng hóa đơn mẫu. "
        "Parser ưu tiên dòng tổng cộng và thanh toán, rồi tổng tiền và tiền hàng, rồi cụm số đi với đ, vnd, vnđ. "
        "Ngày nhận dd/MM/yyyy và yyyy-MM-dd. Từ điển cửa hàng gán danh mục. "
        "Form kiểm tra cho sửa trước khi ghi. Ảnh chỉ ở trên máy. D1 giữ chữ đã đọc, số tiền, danh mục và ghi chú."
    )
    draw_table(
        pdf,
        ["Trường", "Cách bắt"],
        [
            ["Tổng, ưu tiên 1", "tổng cộng, thanh toán, total, amount due"],
            ["Tổng, ưu tiên 2", "tổng tiền, tiền hàng, cộng tiền, tiền mặt"],
            ["Cụm số", "1.234, 1,234 và số liền 150000"],
            ["Đơn vị", "Số cạnh đ, vnd, vnđ, d. Quét từ dưới lên."],
            ["Ngày", "dd/MM/yyyy và yyyy-MM-dd"],
            ["Cửa hàng", "Từ điển thương hiệu, rồi vài dòng đầu của hóa đơn"],
        ],
        [40, 138],
    )

    pdf.section_header("6. Tài khoản và đồng bộ")
    pdf.body_p(
        "Tên tài khoản là 3 đến 24 ký tự thường, số hoặc gạch dưới. Mật khẩu từ 6 đến 72 ký tự. "
        "Server tạo salt, tính SHA-256 của salt và mật khẩu bằng Web Crypto, chỉ lưu hash. "
        "Phiên là 32 byte hex. Client gửi Authorization: Bearer. Sai mật khẩu trả invalid_login. "
        "Hết phiên trả 401 và client xóa token. Đồng bộ theo lô, tối đa 200 thao tác. "
        "Mất mạng thì hàng đợi nằm trên máy. Tài khoản mới không nhận dữ liệu mẫu và không nhận sổ của máy. "
        "Ba bảng D1: users, sessions, expenses. Khóa khoản chi là (device_id, id)."
    )

    pdf.section_header("7. Giao diện, ngôn ngữ, splash và native")
    pdf.body_p(
        "SplashScreen hiện logo trên nền #102343, dòng VKU ĐÀ NẴNG màu vàng và tên VKU Ledger. "
        "Logo mờ dần trong 420 ms. Máy tắt animation thì splash hiện ngay. "
        "Hết splash, người đã đăng nhập vào sổ chi, người chưa đăng nhập vào màn đăng nhập. "
        "Ngôn ngữ mặc định là tiếng Việt. AppText đi cùng flutter_localizations. Nút VI/EN có trên đăng nhập và trong Hệ thống. "
        "Sáng tối có ba mức: theo hệ thống, luôn sáng, luôn tối. Lựa chọn được lưu và áp lại lần mở sau. "
        "Tối dùng chữ kem trên mặt kính đậm, viền vàng mảnh. Dock kính có nút chính Quét hóa đơn. "
        "Sổ chi có tổng tháng, tìm kiếm, lọc và vuốt để xóa. Nút Đăng xuất nằm trên sổ chi và trong Hệ thống. "
        "MethodChannel vn.edu.vku/device_info gọi getBatteryLevel. Android trả pin từ BatteryManager. "
        "Web có thẻ cài ứng dụng qua beforeinstallprompt."
    )

    pdf.section_header("8. Đối chiếu yêu cầu và kiểm thử")
    draw_table(
        pdf,
        ["Hạng mục", "Minh chứng"],
        [
            ["OCR và heuristic", "ocr_service.dart, web_ocr.dart, receipt_parser.dart, form kiểm tra"],
            ["Canvas", "Biểu đồ vành khăn và cột tuần bằng CustomPainter"],
            ["Trạng thái và dữ liệu", "Riverpod 3, SQLite, hàng đợi, D1 theo user"],
            ["Giao diện", "Material 3, sáng/tối/theo hệ thống, splash, đa ngôn ngữ Việt-Anh"],
            ["Native", "platform_service.dart và MainActivity.kt"],
        ],
        [48, 130],
    )
    pdf.body_p(
        "flutter test trên receipt_parser_test.dart phủ Highlands Coffee (122.040 đ, ngày 22/10/2026) và các dạng dấu chấm, dấu phẩy. "
        "Thử API với hai tài khoản: user A ghi một khoản, user B nhận danh sách rỗng, đăng nhập lại A vẫn thấy khoản của A. "
        "Sai mật khẩu và request không token đều bị từ chối. Hai tài khoản thử đã được xóa sau khi kiểm tra."
    )

    pdf.section_header("9. Kết luận")
    pdf.body_p(
        "VKU Ledger ghép OCR trên thiết bị, parser hóa đơn Việt Nam, sổ ngoại tuyến và Cloudflare D1 có tài khoản riêng. "
        "Người dùng đăng ký, đăng nhập, quét, sửa và chỉ thấy chi tiêu của mình."
    )
    pdf.ln(4)
    pdf.set_font("ArialVN", "I", 9)
    pdf.set_text_color(71, 85, 105)
    pdf.cell(0, 5, "Đà Nẵng, tháng 10 năm 2026", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("ArialVN", "B", 10)
    pdf.set_text_color(15, 23, 42)
    pdf.cell(0, 5, "Nguyễn Minh Duy", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("ArialVN", "", 9)
    pdf.cell(0, 5, "MSSV 23IT038", align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.output(str(OUT))
    print(f"Wrote {OUT} ({pdf.page_no()} pages)")


if __name__ == "__main__":
    main()
