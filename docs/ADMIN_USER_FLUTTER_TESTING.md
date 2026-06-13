# Checklist kiểm thử Admin User Flutter

## Chuẩn bị

- Chạy backend Spring Boot và đảm bảo endpoint admin dùng chung base URL hiện tại của app.
- Đăng nhập bằng tài khoản có role `ADMIN` hoặc `ROLE_ADMIN`.
- Nếu test trên Android emulator, kiểm tra app đang trỏ về backend qua `10.0.2.2` khi backend chạy ở máy host.

## Luồng danh sách và chi tiết

- Vào màn danh sách người dùng trong Admin.
- Kiểm tra danh sách user load được, không bị trùng item khi kéo load thêm.
- Dùng tìm kiếm và bộ lọc trạng thái/role.
- Bấm `Chi tiết` ở một user.
- Xác nhận route `/admin/users/detail` mở đúng màn `Chi tiết người dùng`.
- Xác nhận màn detail hiển thị loading trước khi có dữ liệu.
- Kiểm tra header có avatar, họ tên, email, số điện thoại, trạng thái và role.
- Kiểm tra section `Thông tin tài khoản` có ID, username, họ tên, email, số điện thoại, giới tính, ngày sinh, provider đăng nhập, ngày tạo và ngày cập nhật.
- Bấm refresh trong AppBar và xác nhận dữ liệu được tải lại một lần.

## Thao tác tài khoản

- Với user `ACTIVE`, bấm `Khóa tài khoản`, xác nhận dialog và kiểm tra trạng thái cập nhật ngay trên detail.
- Với user `BLOCKED`, bấm `Mở khóa tài khoản` và kiểm tra trạng thái cập nhật ngay trên detail.
- Với user `INACTIVE`, bấm `Kích hoạt tài khoản` và kiểm tra trạng thái về `Đang hoạt động`.
- Bấm `Gán vai trò`, chọn `PHARMACIST`, xác nhận role được thêm ngay trên detail.
- Xóa role `PHARMACIST`, xác nhận role biến mất ngay trên detail.
- Bấm `Đặt lại mật khẩu`, nhập mật khẩu mới và xác nhận mật khẩu trùng nhau, kiểm tra có thông báo thành công.
- Bấm `Vô hiệu hóa tài khoản`, xác nhận màn detail pop về list và list refresh.

## Quyền truy cập và tự thao tác

- Đăng nhập bằng customer và thử truy cập route admin, xác nhận bị chặn.
- Đăng nhập admin và mở detail của chính tài khoản admin hiện tại.
- Kiểm tra admin không tự khóa chính mình.
- Kiểm tra admin không tự vô hiệu hóa chính mình.
- Kiểm tra role `ADMIN` của chính admin không thể xóa từ UI.

## Endpoint đang dùng

- `GET /api/v1/admin/users/{userId}`
- `PUT /api/v1/admin/users/{userId}/status`
- `PUT /api/v1/admin/users/{userId}/block`
- `PUT /api/v1/admin/users/{userId}/unlock`
- `PUT /api/v1/admin/users/{userId}/reset-password`
- `POST /api/v1/admin/users/{userId}/roles`
- `DELETE /api/v1/admin/users/{userId}/roles/{roleName}`
- `DELETE /api/v1/admin/users/{userId}`

## Kiểm tra dữ liệu

- List refresh sau khi detail trả `true`.
- Detail không gọi API trong `build`.
- Detail không gọi API nếu `userId` rỗng.
- Các lỗi backend hiển thị bằng tiếng Việt.
- Không có request admin nào tự hard-code base URL.
