import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminMenuItem(
        icon: Icons.category_rounded,
        title: 'Quản lý danh mục',
        description: 'Thêm, sửa và quản lý danh mục sản phẩm',
        routeName: AppRoutes.adminCategories,
      ),
      _AdminMenuItem(
        icon: Icons.sell_rounded,
        title: 'Quản lý thương hiệu',
        description: 'Quản trị thương hiệu và logo',
        routeName: AppRoutes.adminBrands,
      ),
      _AdminMenuItem(
        icon: Icons.local_offer_rounded,
        title: 'Quản lý voucher',
        description: 'Tạo và quản lý mã khuyến mãi',
        routeName: AppRoutes.adminVouchers,
      ),
      _AdminMenuItem(
        icon: Icons.local_pharmacy_rounded,
        title: 'Quản lý nhà thuốc',
        description: 'Thông tin chi nhánh, địa chỉ và giờ mở cửa',
        routeName: AppRoutes.adminPharmacies,
      ),
      _AdminMenuItem(
        icon: Icons.inventory_2_rounded,
        title: 'Quản lý tồn kho',
        description: 'Cập nhật số lượng sản phẩm theo nhà thuốc',
        routeName: AppRoutes.adminInventory,
      ),
      _AdminMenuItem(
        icon: Icons.people_alt_rounded,
        title: 'Quản lý người dùng',
        description: 'Khóa tài khoản, gán vai trò và quản lý người dùng',
        routeName: AppRoutes.adminUsers,
      ),
      _AdminMenuItem(
        icon: Icons.history_rounded,
        title: 'Lịch sử hoạt động',
        description: 'Theo dõi thao tác quản trị trong hệ thống',
        routeName: AppRoutes.adminActivityLogs,
      ),
      _AdminMenuItem(
        icon: Icons.notifications_active_rounded,
        title: 'Gửi thông báo',
        description: 'Gửi thông báo hệ thống đến người dùng',
        routeName: AppRoutes.adminNotificationSend,
      ),
      const _AdminMenuItem(
        icon: Icons.settings_rounded,
        title: 'Cài đặt hệ thống',
        description: 'Kiểm tra kết nối API, đồng bộ dữ liệu, thông báo FCM',
        routeName: AppRoutes.appSettings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _AdminMenuTile(item: items[index]),
      ),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    this.routeName,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? routeName;
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({required this.item});

  final _AdminMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightBlue,
          child: Icon(item.icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(item.description),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          final routeName = item.routeName;
          if (routeName == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng đang được cập nhật.')),
            );
            return;
          }

          Navigator.of(context).pushNamed(routeName);
        },
      ),
    );
  }
}
