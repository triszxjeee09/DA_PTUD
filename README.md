# An Tâm Pharma — Flutter

Đồ án ứng dụng nhà thuốc viết bằng Flutter. Mã nguồn được phục hồi từ `Da_LTTD.zip`. Backend lưu dữ liệu demo bền vững trong SQLite; app Android cũng lưu catalog vào SQLite trên thiết bị để xem lại khi mất mạng.

## Chạy backend

Yêu cầu Python 3.10 trở lên (không cần cài thư viện ngoài):

```powershell
cd backend
python app.py
```

API chạy tại `http://localhost:8082/api/v1`; kiểm tra `http://localhost:8082/api/v1/health`. CSDL được tạo tại `backend/data/an_tam_pharma.sqlite3`.

Tài khoản mẫu (mật khẩu chung `12345678`):

| Vai trò | Email | Username |
| --- | --- | --- |
| Admin | `ductri@antam.local` | `ductri` |
| Dược sĩ | `ngoctien@antam.local` | `ngoctien` |
| Khách hàng | `khachhang@antam.local` | `khachhang` |

Đây là dữ liệu demo local; đổi mật khẩu trước khi dùng ở môi trường thật.

## Chạy Flutter trong Android Studio

1. Cài Flutter SDK và Android SDK, mở thư mục gốc `Da_LTTD` trong Android Studio. Android application ID là `vn.antam.pharma`.
2. Chạy `flutter pub get` trong Terminal của Android Studio.
3. Khởi động backend trước, sau đó chạy app trên emulator. Emulator Android mặc định gọi API qua `10.0.2.2:8082`.
4. Với điện thoại thật, dùng IP LAN máy tính: `flutter run --dart-define=API_BASE_URL=http://<IP-may-tinh>:8082/api/v1`.

Đăng nhập bằng email, username hoặc số điện thoại. Google Sign-In đã được gỡ khỏi ứng dụng vì backend đồ án chưa hỗ trợ OAuth.

## Firebase và tích hợp ngoài

Ứng dụng khởi động bình thường khi chưa có Firebase. FCM push thật cần Firebase project, `google-services.json` và service account cho backend; xem `docs/FIREBASE_SETUP.md`. Backend hiện hỗ trợ tải ảnh lên thư mục `backend/uploads` (giới hạn 15 MB, JPG/PNG/WEBP/PDF), OTP đặt lại mật khẩu demo trả mã `123456` trực tiếp trong response, thông báo trong ứng dụng/FCM tùy cấu hình và thanh toán COD. Email/OTP gửi thật và VNPay chưa được cấu hình; VNPay trả lỗi rõ ràng thay vì giả lập giao dịch thành công.

## Kiểm thử

`docs/LOCAL_RUN_AND_TEST_STATUS.md` ghi rõ các kiểm tra chạy được và giới hạn môi trường. Backend có test smoke độc lập trong `backend/test_api.py`:

```powershell
python backend/test_api.py
```

## Tính năng bổ sung

Xem [docs/TINH_NANG_BO_SUNG.md](docs/TINH_NANG_BO_SUNG.md) để biết các chức năng đã bổ sung (SQLite offline, FCM, chat dược sĩ, nhắc thuốc, hồ sơ sức khỏe, điểm thưởng...).
