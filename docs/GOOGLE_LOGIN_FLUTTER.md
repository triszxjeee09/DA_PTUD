# Google Login Flutter Checklist

## Cấu hình bắt buộc

- Web Client ID: dùng Web Client ID làm `serverClientId` trong Flutter và làm audience để backend xác minh Google ID Token.
- Android Client ID: tạo OAuth Android Client trong cùng Google Cloud project với Web Client.
- Package name: phải khớp `applicationId` Android của app.
- SHA-1 debug: thêm SHA-1 của debug keystore vào Android OAuth Client.
- SHA-1 release: thêm SHA-1 release nếu chạy bản release hoặc build ký thật.
- Backend endpoint: `POST /auth/google`.
- Body Flutter gửi: chỉ `{ "idToken": "..." }`.
- Backend trả về: JWT backend gồm `accessToken`, `refreshToken`, `tokenType`, `expiresIn`, `user`.

Không dùng Client Secret trong Flutter. Không dùng Android Client ID làm `serverClientId`. Không log Google ID Token.

## Cách chạy Android emulator

1. Chạy backend Spring Boot.
2. Đảm bảo app Flutter dùng base URL Android emulator `http://10.0.2.2:8080/api/v1`.
3. Chạy:

```bash
flutter clean
flutter pub get
flutter run
```

4. Nếu vừa sửa cấu hình Google Cloud, gỡ app cũ khỏi emulator rồi cài lại.

## Luồng login

1. Người dùng bấm `Đăng nhập với Google`.
2. Flutter gọi Google Sign-In để lấy Google ID Token.
3. Flutter gửi ID Token tới `POST /auth/google`.
4. Backend xác minh ID Token với Google, tạo hoặc liên kết user.
5. Backend trả JWT của An Tâm Pharma.
6. Flutter chỉ lưu `accessToken` và `refreshToken` backend trả về.
7. Flutter cập nhật `currentUser` từ backend response.

Không gửi email, fullName, avatar, googleId, Android Client ID hoặc Client Secret để login.

## Luồng role

- Role chỉ lấy từ backend response hoặc `GET /auth/me`.
- `ADMIN` hoặc `ROLE_ADMIN` vào `/admin`.
- `PHARMACIST` hoặc `ROLE_PHARMACIST` vào `/pharmacist` nếu route đang có.
- `CUSTOMER`, `ROLE_CUSTOMER`, hoặc roles rỗng vào `/main`.
- Flutter không tự cấp quyền Admin từ thông tin Google.

## Splash/session

- Không dùng Google silent sign-in làm nguồn xác thực chính.
- Nguồn xác thực chính là JWT backend:
  - kiểm tra access token,
  - gọi `GET /auth/me`,
  - nếu token hợp lệ thì điều hướng theo role,
  - nếu không hợp lệ thì clear token và về `/login`.
- Không bắt người dùng Google Sign-In lại khi mở app nếu JWT backend còn hợp lệ.

## Logout

1. Hủy FCM device token nếu có.
2. Gọi backend logout nếu có.
3. Clear `accessToken` và `refreshToken`.
4. Gọi `GoogleAuthService.signOut()` an toàn.
5. Điều hướng về `/login` và clear stack.

Logout vẫn được xem là thành công nếu backend logout hoặc Google signOut lỗi cục bộ.

## Lỗi thường gặp

### DEVELOPER_ERROR hoặc lỗi cấu hình Google

Kiểm tra:

- `applicationId` Android có khớp package name trong Google Cloud không.
- SHA-1 debug đã thêm đúng chưa.
- SHA-1 release đã thêm chưa nếu chạy release.
- OAuth Android Client có nằm cùng Google Cloud project với Web Client không.
- Web Client ID có được dùng làm `serverClientId` không.
- Backend có xác minh đúng Web Client ID không.
- Google Cloud có thể cần thời gian để cấu hình mới có hiệu lực.

Sau khi sửa cấu hình:

```bash
flutter clean
flutter pub get
```

Gỡ app khỏi emulator rồi cài lại. Không chữa tạm bằng cách thay Web Client ID thành Android Client ID.

### Backend trả 401

- Kiểm tra backend audience/Web Client ID.
- Kiểm tra đồng hồ máy backend.
- Kiểm tra ID Token gửi lên chưa hết hạn.

### Backend trả 409

- Google account đã được liên kết với user khác.
- Backend cần có chính sách merge/link rõ ràng.

## Checklist test thật

- [ ] Gỡ app cũ khỏi emulator.
- [ ] Chạy backend.
- [ ] Mở app.
- [ ] Bấm `Đăng nhập với Google`.
- [ ] Chọn Gmail.
- [ ] Backend tạo hoặc liên kết user.
- [ ] Flutter nhận JWT backend.
- [ ] CUSTOMER vào `/main`.
- [ ] ADMIN đã được gán sẵn trong backend vào `/admin`.
- [ ] Đóng mở app vẫn đăng nhập bằng JWT backend.
- [ ] Logout rồi đăng nhập tài khoản Google khác.
- [ ] Kiểm tra `users.google_id` và `auth_provider` trong database.
- [ ] Không có Google ID Token trong log, database, SharedPreferences, secure storage hoặc local storage.
