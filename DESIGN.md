# VKU Ledger

Sổ chi tiêu hóa đơn cho sinh viên VKU. Giao diện phục vụ việc ghi và quét, không phải một poster tài chính.

## Read

Utility register. Light and dark both ship. System theme is the default. Accent is gold on navy. Dials: variance 5, motion 4, density 5. The primary action is quét hóa đơn.

## Tokens

- Navy `#1E3A8A` for actions and the hero.
- Splash and icon field `#102343`.
- Gold `#E8A317` for the scan action, the receipt total bar, and the splash eyebrow.
- Paper text on splash `#F4F0E6`.
- Radius family: 16 for controls, 26 for the hero and the dock.
- Type: Inter. Body height 1.45. Headlines at least 1.2.

## Voice

Tiếng Việt, câu ngắn, động từ đứng trước. Không emoji trong chrome. Nút nói kết quả: "Quét hóa đơn", "Xóa sạch", "Đồng bộ ngay".

## Decisions

- 2026-10-09: Giữ navy VKU, thêm vàng hóa đơn làm accent duy nhất cho hành động chính.
- 2026-10-09: Logo là hóa đơn kem trong khung quét vàng. Dùng cho icon, splash, và đầu sổ chi.
- 2026-10-09: Cloudflare D1 là sổ trên mây, SQLite là bản trên máy. Mỗi cài đặt một khóa thiết bị.
