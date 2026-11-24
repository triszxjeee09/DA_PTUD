# Firebase cho Android và backend

Firebase project `an-tam-pharma-24ae0` đã đăng ký app Android `vn.antam.pharma` trên gói Spark miễn phí. `google-services.json` đã được đặt tại `android/app/google-services.json`; Gradle tự áp dụng Google Services plugin 4.6.0 khi file có mặt. App tự khởi tạo Firebase và đăng ký FCM token; nếu build ở máy khác chưa có config, app vẫn chạy nhưng không có push.

Firebase Admin service-account key đã được tạo và lưu ngoài repo tại `%LOCALAPPDATA%\AnTamPharma\firebase-service-account.json`. `backend/run.ps1` tự đặt `FIREBASE_SERVICE_ACCOUNT_FILE` nếu tìm thấy file đó. Khi chạy backend trực tiếp bằng `python backend/app.py`, đặt biến môi trường này trước khi chạy. Không gửi file key qua chat, không đưa vào Git, và không dùng credential này trên máy khác.

Đã cài `firebase-admin` theo `backend/requirements-firebase.txt`. Khởi động lại backend bằng `powershell -ExecutionPolicy Bypass -File backend/run.ps1`; log cần có `Firebase Admin push is configured`. Backend chỉ gửi tới thiết bị sau khi app đăng nhập và đăng ký FCM token. Test API hiện kiểm tra batching với transport giả; cần thiết bị có token để xác nhận push nhận được thật.
