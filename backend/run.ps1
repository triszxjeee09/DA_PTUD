$ErrorActionPreference = 'Stop'
$backendDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $backendDir
$firebaseKey = Join-Path $env:LOCALAPPDATA 'AnTamPharma\firebase-service-account.json'
if (Test-Path -LiteralPath $firebaseKey) {
    $env:FIREBASE_SERVICE_ACCOUNT_FILE = $firebaseKey
}
# ===================== CẤU HÌNH THANH TOÁN (SỬA TẠI ĐÂY) =====================
# Chuyển khoản ngân hàng -> mã QR VietQR được tạo từ 4 dòng dưới đây.
$env:PHARMA_BANK_ID      = '970422'                  # mã BIN ngân hàng (xem bảng trong docs/TINH_NANG_BO_SUNG.md)
$env:PHARMA_BANK_NAME    = 'MB Bank'                 # tên ngân hàng hiển thị trong app
$env:PHARMA_BANK_ACCOUNT = '0123456789'              # SỐ TÀI KHOẢN THẬT của bạn
$env:PHARMA_BANK_OWNER   = 'NHA THUOC AN TAM'        # tên chủ tài khoản, VIẾT HOA KHÔNG DẤU
$env:PHARMA_HOTLINE      = '1900 1234'               # hotline hiển thị trong Trung tâm trợ giúp
# MoMo (mặc định dùng sandbox). Khi có tài khoản MoMo Business, bỏ dấu # và điền:
# $env:PHARMA_MOMO_PARTNER_CODE = '...'
# $env:PHARMA_MOMO_ACCESS_KEY   = '...'
# $env:PHARMA_MOMO_SECRET_KEY   = '...'
# $env:PHARMA_MOMO_ENDPOINT     = 'https://payment.momo.vn/v2/gateway/api'
# ===============================================================================
python app.py
