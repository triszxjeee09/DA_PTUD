# Checklist test Admin Category

## Chuẩn bị

- [ ] Backend đang chạy và kết nối đúng base URL.
- [ ] Có tài khoản admin hợp lệ.
- [ ] Có tài khoản customer không có quyền admin.
- [ ] Có ít nhất một danh mục đang hoạt động và một danh mục ngừng hoạt động.
- [ ] Có ít nhất một danh mục đang được sản phẩm sử dụng để test trường hợp xóa bị chặn.

## Luồng chính

- [ ] Login bằng admin.
- [ ] Vào khu vực Admin.
- [ ] Vào menu "Quản lý danh mục".
- [ ] Xem danh sách danh mục.
- [ ] Kéo xuống refresh danh sách.
- [ ] Cuộn gần cuối danh sách và kiểm tra load more.
- [ ] Xác nhận danh sách không bị duplicate khi load more nhiều lần.
- [ ] Tìm danh mục theo tên.
- [ ] Tìm danh mục theo slug.
- [ ] Đổi keyword tìm kiếm và kiểm tra danh sách reset về trang đầu.
- [ ] Lọc danh mục "Đang hoạt động".
- [ ] Lọc danh mục "Ngừng hoạt động".
- [ ] Đổi filter active/inactive và kiểm tra danh sách reset về trang đầu.
- [ ] Chọn "Tất cả" và kiểm tra danh sách hiển thị lại đầy đủ.

## Thêm danh mục

- [ ] Bấm "+ Thêm danh mục".
- [ ] Nhập tên danh mục, kiểm tra slug tự sinh.
- [ ] Sửa slug thủ công, sau đó đổi tên và kiểm tra slug không bị ghi đè.
- [ ] Bỏ trống tên danh mục, kiểm tra lỗi "Tên danh mục không được rỗng".
- [ ] Bỏ trống slug, kiểm tra lỗi "Slug không được rỗng".
- [ ] Nhập slug có chữ hoa/ký tự đặc biệt, kiểm tra lỗi slug.
- [ ] Nhập URL ảnh không hợp lệ, kiểm tra lỗi URL.
- [ ] Không chọn ảnh và lưu, kiểm tra vẫn thêm được danh mục.
- [ ] Thêm danh mục mới không có danh mục cha.
- [ ] Thêm danh mục có danh mục cha.
- [ ] Upload ảnh danh mục từ thư viện.
- [ ] Khi upload ảnh, kiểm tra hiển thị "Đang tải ảnh..." và disable nút "Chọn ảnh".
- [ ] Sau khi upload xong, kiểm tra preview ảnh hiển thị đúng.
- [ ] Lưu thành công và kiểm tra SnackBar "Thêm danh mục thành công".
- [ ] Quay lại màn danh sách và kiểm tra danh sách được refresh.

## Sửa danh mục

- [ ] Bấm "Sửa" một danh mục.
- [ ] Kiểm tra form được fill đúng tên, slug, mô tả, URL ảnh, danh mục cha và trạng thái.
- [ ] Kiểm tra dropdown danh mục cha không cho chọn chính danh mục đang sửa.
- [ ] Sửa tên/mô tả/trạng thái.
- [ ] Upload ảnh danh mục mới.
- [ ] Lưu thành công và kiểm tra SnackBar "Cập nhật danh mục thành công".
- [ ] Quay lại màn danh sách và kiểm tra danh sách được refresh.

## Xóa hoặc ẩn danh mục

- [ ] Bấm "Xóa" hoặc "Ẩn".
- [ ] Kiểm tra dialog xác nhận có title "Xóa danh mục".
- [ ] Bấm "Hủy", kiểm tra không thay đổi dữ liệu.
- [ ] Bấm "Xóa", kiểm tra gọi API xóa danh mục.
- [ ] Xóa thành công, kiểm tra SnackBar "Xóa danh mục thành công".
- [ ] Xóa danh mục đang có sản phẩm và backend chặn, kiểm tra hiển thị message backend trả về.
- [ ] Khi xóa bị chặn, kiểm tra app không crash và danh sách không bị mất item sai.

## Lỗi API và phân quyền

- [ ] Hết hạn token hoặc API trả 401.
- [ ] Kiểm tra app điều hướng về Login.
- [ ] Kiểm tra message "Phiên đăng nhập đã hết hạn".
- [ ] API trả 403 với tài khoản không đủ quyền.
- [ ] Kiểm tra hiển thị "Bạn không có quyền quản lý danh mục".
- [ ] Kiểm tra không logout khi API trả 403.
- [ ] Test tài khoản customer không vào được route admin category.
- [ ] Tạo hoặc sửa danh mục với slug đã tồn tại.
- [ ] Kiểm tra hiển thị "Slug danh mục đã tồn tại".
- [ ] Backend trả `validationErrors`, kiểm tra app hiển thị message đầu tiên.
- [ ] Backend trả lỗi xóa danh mục có sản phẩm, kiểm tra app hiển thị message backend.

## Ảnh danh mục

- [ ] Danh mục có `imageUrl` hợp lệ hiển thị preview.
- [ ] Danh mục có `imageUrl` lỗi hiển thị icon mặc định và không crash.
- [ ] Danh mục không có `imageUrl` hiển thị icon mặc định.
- [ ] Nhập URL ảnh thủ công và lưu thành công.
- [ ] Upload ảnh lỗi, kiểm tra SnackBar "Không thể tải ảnh danh mục".

## Kiểm tra phía khách hàng

- [ ] Vào CategoryScreen phía khách hàng.
- [ ] Kiểm tra CategoryScreen phía khách hàng có hiển thị danh mục mới không.
- [ ] Kiểm tra CategoryProvider của customer vẫn load danh mục bình thường.
- [ ] Kiểm tra route danh mục phía khách hàng không bị ảnh hưởng bởi route admin.
