# Checklist test thủ công flow đặt hàng và email xác nhận

Tài liệu này dùng để kiểm tra nhanh trong lúc demo flow Flutter tạo đơn hàng và backend gửi email xác nhận qua SendGrid.

## Trước khi test

- [ ] Backend đã cấu hình `SENDGRID_API_KEY`.
- [ ] `SENDGRID_FROM_EMAIL` đã được verify trên SendGrid.
- [ ] `SENDGRID_ORDER_TEMPLATE_ID` đúng với template email xác nhận đơn hàng.
- [ ] Backend đang chạy và truy cập được từ thiết bị/emulator.
- [ ] Flutter `baseUrl` đang trỏ đúng backend hiện tại.
- [ ] Đã đăng nhập tài khoản test trên Flutter app.
- [ ] User đặt hàng có email trong tài khoản.
- [ ] Giỏ hàng có ít nhất một sản phẩm.
- [ ] Đã chọn địa chỉ giao hàng.
- [ ] Nếu giỏ hàng có thuốc kê đơn, đã chọn đơn thuốc phù hợp.
- [ ] Nếu dùng voucher, voucher còn hiệu lực và đã được áp dụng.

## Khi bấm "Đặt hàng"

- [ ] Flutter console có log request tạo đơn hàng với các trường:
  - `addressId`
  - `paymentMethod`
  - `voucherId`
  - `prescriptionId`
  - `note`
- [ ] Log Flutter không in token.
- [ ] Log Flutter không in thông tin nhạy cảm của người dùng.
- [ ] Flutter console có log `[ORDER] Bắt đầu tạo đơn hàng`.

## Sau khi tạo đơn thành công

- [ ] Flutter console có log `[ORDER] Tạo đơn hàng thành công: {orderCode}`.
- [ ] App chuyển sang màn `OrderSuccessScreen`.
- [ ] `OrderSuccessScreen` hiển thị mã đơn hàng.
- [ ] `OrderSuccessScreen` hiển thị tổng thanh toán.
- [ ] `OrderSuccessScreen` hiển thị phương thức thanh toán.
- [ ] `OrderSuccessScreen` hiển thị card "Email xác nhận".
- [ ] Nếu user có email, màn hình hiển thị đúng email nhận xác nhận.
- [ ] Nếu user chưa có email, màn hình hiển thị cảnh báo và nút "Cập nhật email".

## Kiểm tra backend và email

- [ ] Backend log có ghi nhận API tạo đơn hàng `POST /api/v1/orders`.
- [ ] Backend log có bước gọi gửi email xác nhận đơn hàng.
- [ ] Backend không báo lỗi SendGrid.
- [ ] Gmail nhận được email xác nhận đơn hàng.
- [ ] Kiểm tra cả hộp thư đến.
- [ ] Kiểm tra mục Spam.
- [ ] Kiểm tra mục Promotions.
- [ ] Nội dung email có đúng mã đơn hàng.
- [ ] Nội dung email có đúng tổng thanh toán.
- [ ] Nội dung email có đúng thông tin cơ bản của đơn hàng.

## Khi tạo đơn thất bại

- [ ] Flutter console có log `[ORDER] Tạo đơn hàng thất bại: {message}`.
- [ ] App không chuyển sang `OrderSuccessScreen`.
- [ ] Người dùng thấy thông báo lỗi phù hợp.
- [ ] Không có email xác nhận được gửi khi đơn hàng không tạo thành công.

## Ghi chú demo

- Flutter chỉ gọi API tạo đơn hàng.
- Flutter không gọi API gửi email riêng.
- Flutter không biết SendGrid gửi email thành công hay thất bại.
- Việc gửi email xác nhận do backend xử lý sau khi tạo đơn hàng thành công.
