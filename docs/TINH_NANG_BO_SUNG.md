# Tính năng bổ sung so với `tailieu.docx`

Ứng dụng Flutter kết nối **3 lớp dữ liệu**:

| Lớp | Công nghệ | Dùng cho |
|---|---|---|
| API | REST (`backend/app.py`, Dio ở Flutter) | Toàn bộ nghiệp vụ: sản phẩm, đơn hàng, chat, hỗ trợ, điểm thưởng... |
| SQLite | `sqflite` trên máy + SQLite ở backend | Offline-first: **nhắc thuốc, hồ sơ sức khỏe, yêu thích** (đồng bộ 2 chiều khi có mạng) |
| Firebase | FCM (`firebase_messaging`) | Đẩy thông báo: nhắc uống thuốc đúng giờ, dược sĩ trả lời, đơn hàng, giảm giá/có hàng lại |

Cơ chế offline-first nằm ở `lib/core/sync/synced_collection.dart` + `lib/core/database/local_record_store.dart`.

## Danh sách chức năng mới

| Mục tài liệu | Chức năng | Màn hình / file chính |
|---|---|---|
| 3, 7 | Lọc nâng cao (giá, dạng bào chế, đối tượng, nhà sản xuất, đánh giá, còn hàng, sắp xếp); tìm theo triệu chứng/hoạt chất không dấu | `product_filter_sheet.dart`, `backend/extras.py` |
| 4 | Thông tin thuốc đầy đủ (đối tượng, dạng bào chế, chống chỉ định...), 6 nhóm sản phẩm + dữ liệu mẫu | `product_detail_screen.dart`, `extras.seed_catalog` |
| 5, 18 | Sản phẩm yêu thích + thông báo giảm giá/có hàng lại | `lib/features/favorite` |
| 8 | Thanh toán chuyển khoản QR (VietQR) + admin bấm "Xác nhận đã nhận tiền" | `bank_transfer_screen.dart`, `admin_order_detail_screen.dart` |
| 8 | Thanh toán **MoMo** (sandbox mặc định, đổi sang thật bằng biến môi trường) | `backend/momo.py`, `momo_webview_screen.dart` |
| 10 | Mua lại nhanh, hóa đơn, thuốc thường dùng + gợi ý mua lại định kỳ | `frequent_products_screen.dart`, `invoice_screen.dart` |
| 11 | Nhà thuốc gần bạn: GPS, khoảng cách, chỉ đường Google Maps, gọi điện | `pharmacy_near_me_screen.dart`, `core/location` |
| 12 | Đánh giá: chỉ người đã mua, ảnh, lọc theo sao, nhà thuốc phản hồi | `product_review_list_screen.dart`, `staff_review_reply_screen.dart` |
| 13 | Nhắc uống thuốc (SQLite + FCM), lịch sử tuân thủ | `lib/features/reminder` |
| 14 | Hồ sơ sức khỏe gia đình, BMI, theo dõi huyết áp/đường huyết/cân nặng + biểu đồ + gợi ý đi khám | `lib/features/health` |
| 15 | Chat với dược sĩ (ảnh, gợi ý sản phẩm, trạng thái online, ghi chú tư vấn) + chatbot | `lib/features/chat` |
| 16 | Điểm thưởng, hạng thành viên, đổi voucher | `lib/features/loyalty` |
| 17 | Thông báo mới + điều hướng (nhắc thuốc, tư vấn, hỗ trợ, điểm, có hàng lại) | `notification_navigation_handler.dart` |
| 19 | Giao diện **Dược sĩ** (thay màn hình placeholder): duyệt đơn thuốc, tư vấn, hỗ trợ, phản hồi đánh giá | `lib/features/pharmacist` |
| 20 | Admin: chi tiết đơn, hoàn tiền, xem hóa đơn, điểm thưởng & lịch sử mua theo khách, thêm thông tin thuốc | `admin_order_detail_screen.dart`, `admin_user_loyalty_card.dart` |
| 21, 22 | Trung tâm trợ giúp: FAQ, hotline gọi trực tiếp, khiếu nại/góp ý (ticket), cài đặt | `lib/features/support`, `settings_screen.dart` |
| — | Khuyến mãi / Lịch sử thanh toán / Đánh giá của tôi (trước đây là placeholder) | `voucher_list_screen.dart`, `payment_history_screen.dart`, `my_reviews_screen.dart` |

## API mới (backend/extras.py)

`/favorites`, `/reminders` (+`/logs`), `/health/members`, `/health/members/{id}/metrics`, `/loyalty`, `/loyalty/redeem`,
`/chat/my-conversation`, `/chat/conversations/{id}/messages|notes|read`, `/chat/presence`, `/chat/bot`,
`/support/faqs|info|tickets|staff/tickets`, `/orders/{id}/reorder|invoice`, `/orders/frequent-products`,
`/orders/admin/{id}` + `/refund`, `/payments/bank-qr`, `/reviews/staff`, `/reviews/{id}/reply`,
`/admin/users/{id}/points|orders`.

## Thanh toán MoMo và chuyển khoản

Luồng MoMo: app gọi `POST /payments/momo/create-payment` → backend ký HMAC-SHA256 và gọi MoMo API v2 (`captureWallet`) →
app mở `payUrl` trong WebView → khách thanh toán → app gọi `POST /payments/momo/verify` → backend hỏi lại MoMo (API `query`)
và chỉ đánh dấu `PAID` khi MoMo xác nhận và số tiền khớp. Vì vậy **không cần địa chỉ công khai** để chạy thử;
IPN (`/payments/momo/ipn`, có kiểm tra chữ ký) chỉ là kênh bổ sung khi backend có địa chỉ công khai (VD ngrok).

Mặc định dùng khóa **sandbox công khai** của MoMo (xem `backend/momo.py`; hãy đối chiếu với https://developers.momo.vn).
Khi có tài khoản MoMo Business, đặt trước khi chạy backend:

```powershell
$env:PHARMA_MOMO_PARTNER_CODE = "..."
$env:PHARMA_MOMO_ACCESS_KEY   = "..."
$env:PHARMA_MOMO_SECRET_KEY   = "..."
$env:PHARMA_MOMO_ENDPOINT     = "https://payment.momo.vn/v2/gateway/api"
$env:PHARMA_PUBLIC_URL        = "https://<địa-chỉ-công-khai>"   # tùy chọn, để nhận IPN
```

Chuyển khoản ngân hàng: đặt `PHARMA_BANK_ID`, `PHARMA_BANK_NAME`, `PHARMA_BANK_ACCOUNT`, `PHARMA_BANK_OWNER`. Admin kiểm tra tiền
trong app ngân hàng rồi bấm **Xác nhận đã nhận tiền** ở chi tiết đơn (`POST /orders/admin/{id}/confirm-payment`).

## Sửa lỗi có sẵn trong backend

* **Bảo mật:** khách có thể tự gọi `PUT /payments/{id}/status` để đánh dấu đơn của chính mình là `PAID`. Nay chỉ admin (hoặc luồng xác minh MoMo) mới đặt được `PAID/SUCCESS/REFUNDED`.

* Transaction SQLite được commit **sau khi** trả response → client gọi API kế tiếp có thể đọc dữ liệu cũ (test cũ chạy lúc đạt lúc hỏng). Nay commit trước khi gửi.
* App dùng trạng thái đơn `PREPARING/DELIVERED` nhưng backend chỉ biết `PROCESSING/COMPLETED` → doanh thu và nhãn trạng thái sai. Nay `DELIVERED` được coi là hoàn tất.

## Chạy

```powershell
cd backend
./run.ps1                      # hoặc: python app.py   (tự migrate CSDL, không mất dữ liệu cũ)
cd ..
flutter pub get                # thêm 2 gói mới: geolocator, url_launcher
flutter run
```

Biến môi trường tùy chọn cho backend: `PHARMA_HOTLINE`, `PHARMA_BANK_ID`, `PHARMA_BANK_NAME`, `PHARMA_BANK_ACCOUNT`,
`PHARMA_BANK_OWNER` (thông tin QR chuyển khoản), `PHARMA_TZ_OFFSET` (mặc định 7).
Nhắc thuốc đúng giờ cần **backend đang chạy** và đã cấu hình Firebase Admin (xem `docs/FIREBASE_SETUP.md`).

## Kiểm thử

```powershell
python backend/test_api.py       # nghiệp vụ cũ
python backend/test_extras.py    # tính năng mới + scheduler nhắc thuốc
flutter test                     # gồm test/unit/health_*, reminder_schedule_test
```

## Giới hạn đã biết

* VNPay cần tài khoản merchant nên vẫn trả lỗi 503; COD, chuyển khoản QR và MoMo dùng được.
* MoMo sandbox chỉ chạy được khi máy có Internet; giao dịch thật cần hợp đồng MoMo Business. Mã Flutter của luồng MoMo chưa chạy thử với trang sandbox thật.
* Chat dùng polling 4 giây qua API (không dùng Firestore) để giữ một nguồn dữ liệu duy nhất.
* Thông tin thuốc, hotline và tài khoản ngân hàng là **dữ liệu mẫu** - cần thay bằng dữ liệu thật trước khi triển khai.
* Mã Flutter mới được viết trong môi trường không có Flutter SDK: đã kiểm tra cú pháp toàn bộ file, chạy thật phần logic thuần Dart
  và toàn bộ backend; **cần chạy `flutter analyze` / `flutter run` một lần** để xác nhận biên dịch trên máy của bạn.
