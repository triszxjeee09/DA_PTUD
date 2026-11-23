# Phục hồi và trạng thái chạy

## Nguồn dự án và dữ liệu

Thư mục Flutter được phục hồi từ `E:/DA_PTUD/Da_LTTD.zip`. ZIP không có backend hoặc CSDL chạy cũ, nên backend Python/SQLite và bộ seed được dựng lại trong workspace. Dữ liệu mới được lưu bền vững tại `backend/data/an_tam_pharma.sqlite3`; không thể khôi phục dữ liệu chỉ tồn tại trong backend đã mất.

Tài khoản seed dùng mật khẩu `12345678`: admin `ductri@antam.local`, dược sĩ `ngoctien@antam.local`, khách hàng `khachhang@antam.local`. Backend tạo 4 danh mục, 3 thương hiệu, 8 sản phẩm, 2 nhà thuốc, tồn kho mỗi nhà thuốc, voucher demo. Không đăng nhập được thì xóa CSDL local để backend tạo lại seed; thao tác này xóa các đơn hàng và dữ liệu người dùng đã thêm.

## Chạy

1. Chạy `powershell -ExecutionPolicy Bypass -File backend/run.ps1` hoặc `python backend/app.py`.
2. Mở `http://127.0.0.1:8082/api/v1/health`; kết quả cần báo `UP` và `SQLite`.
3. Cài Flutter SDK/Android SDK, mở thư mục gốc trong Android Studio, chạy `flutter pub get`.
4. Chạy trên emulator Android. Base URL mặc định là `http://10.0.2.2:8082/api/v1`. Với thiết bị thật, dùng `flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:8082/api/v1` và cho phép kết nối LAN/firewall.

## Kiểm tra đã chạy (20/11/2026)

- `flutter pub get` thành công sau khi bật Windows Developer Mode.
- `flutter analyze --no-pub`: không có lỗi.
- `flutter test --no-pub`: 75 test passed. Flutter hiện có cảnh báo `integration_test plugin was not detected` vì integration test được chạy trong bộ test unit/widget, không phải Android instrumentation.
- `python backend/test_api.py`: toàn bộ luồng API backend/SQLite đạt.
- `flutter build apk --debug --target-platform android-x64 --no-pub`: thành công cho emulator x86_64. `gradlew assembleDebug --offline --max-workers=1`: cũng thành công cho APK phổ thông. Bản mới nhất `build/app/outputs/flutter-apk/app-debug.apk` khoảng 187 MB, chứa arm64-v8a, armeabi-v7a và x86_64. Hai dependency Android annotation extractor nằm trong local Maven repo tùy chọn tại `%LOCALAPPDATA%\AnTamPharma\maven`; Flutter ARMv7 engine artifact đã được cache. Cấu hình native: Gradle 9.3.1, AGP 9.1.0, JDK 25 từ Android Studio.

## Kiểm tra trước đây

`python -m py_compile backend/app.py backend/test_api.py` và `python backend/test_api.py` chạy thành công. Test dùng CSDL/tệp tạm và bao phủ xác thực/đặt lại mật khẩu demo, hồ sơ/địa chỉ, catalog CRUD/slug, nhà thuốc/tồn kho, voucher, review, giỏ hàng/đơn hàng/thanh toán cục bộ, đơn thuốc/upload tệp, dashboard/quản trị user/lịch sử hoạt động, lưu thông báo và chia batch FCM tối đa 500 token. Kiểm tra FCM dùng transport giả; không chứng minh gửi tới thiết bị Firebase thật. Flutter có unit test cho fallback catalog/detail từ SQLite cache và hồi quy đăng nhập sai với token cũ; widget test xác nhận lỗi đăng nhập chỉ hiện một lần trong form. Với đăng nhập sai, backend trả thông báo tiếng Việt; interceptor chỉ coi 401 trên request cần xác thực là phiên hết hạn.

## Phần phụ thuộc cấu hình bên ngoài

- Flutter SDK đã được đặt trong workspace ở `flutter/flutter` (Flutter 3.47.5); Android SDK có platform-tools và Android Studio đã lưu cấu hình máy ảo Pixel 6a API 37, nhưng package `emulator.exe` chưa được cài. Emulator và system image cần cài qua SDK Manager để kiểm tra app trên máy ảo. Android build dùng JDK 25 đi kèm Android Studio.
- Firebase project `an-tam-pharma-24ae0` (Spark, $0/month) đã đăng ký Android app `vn.antam.pharma`; `google-services.json` nằm ở `android/app/google-services.json`, package ID đã đối chiếu và file được `.gitignore` loại khỏi Git. Google Services plugin 4.6.0 tự áp dụng khi file có mặt. App tự khởi tạo Firebase khi config có mặt, nếu thiếu thì vẫn chạy nhưng không có push. Firebase Admin service-account JSON được giữ ngoài repo tại `%LOCALAPPDATA%\AnTamPharma\firebase-service-account.json`; `backend/run.ps1` tự cấu hình file này. Đã cài `firebase-admin`, log backend báo push configured, và FCM dry-run đã xác nhận credential tới bước token validation. Chưa kiểm tra push trên thiết bị thật vì cần đăng ký token từ app.
- OTP hiện là mã demo cố định `123456` trả trực tiếp qua API, không gửi email/SMS. VNPay trả HTTP 503 đến khi có merchant credentials. Token FCM được lưu trong SQLite. Nếu backend chưa có credential, thông báo vẫn được lưu trong ứng dụng; khi cấu hình Firebase Admin, API gửi thêm push FCM và trả số gửi/lỗi.
- Upload tệp hoạt động local trong `backend/uploads`; cần dùng storage ngoài khi triển khai máy chủ thực.
- Tác giả và committer trong lịch sử Git local đã được đổi thành `DucTri`; remote gắn với tài khoản cũ đã được gỡ. Nội dung các file và cây thư mục commit được giữ nguyên.









## Trạng thái chạy hiện tại

- Đã khởi động backend với `FIREBASE_SERVICE_ACCOUNT_FILE` trỏ tới key ngoài repo. Log hiện có `Firebase Admin push is configured`; `GET http://127.0.0.1:8082/api/v1/health` trả HTTP 200, `UP`, `SQLite`.
- Kiểm tra lại trong workspace: `python backend/test_api.py` đạt tất cả nhóm API; `flutter analyze --no-pub` không có vấn đề; `flutter test --no-pub` đạt 75 test; `gradlew assembleDebug --offline --max-workers=1` tạo APK thành công.
- APK Android debug mới nhất: `build/app/outputs/flutter-apk/app-debug.apk` (universal debug). Cài bằng `adb install -r build/app/outputs/flutter-apk/app-debug.apk` khi có thiết bị/emulator.
- Chưa xác minh UI/API/FCM trên emulator. Emulator và Android API 34 Play Store image đang được tải; sau khi cài xong cần mở emulator, cài APK và kiểm tra app. FCM thật cần thiết bị đăng nhập để đăng ký token.

