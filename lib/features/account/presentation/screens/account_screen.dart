import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const Set<String> _availableRoutes = {
    AppRoutes.selectAddress,
    AppRoutes.accountProfile,
    AppRoutes.orders,
    AppRoutes.prescriptions,
    AppRoutes.notifications,
    AppRoutes.paymentHistory,
    AppRoutes.myReviews,
    AppRoutes.appSettings,
    AppRoutes.favorites,
    AppRoutes.reminders,
    AppRoutes.healthTools,
    AppRoutes.loyalty,
    AppRoutes.frequentProducts,
    AppRoutes.helpCenter,
    AppRoutes.chat,
  };

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const _GuestAccountScreen();
    }

    final fullName = user.fullName?.trim();
    final displayName = fullName != null && fullName.isNotEmpty
        ? fullName
        : 'Khách hàng';
    final contact = _readContact(user.email, user.phone);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _AccountHeader(
              displayName: displayName,
              contact: contact,
              avatarUrl: user.avatarUrl,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverToBoxAdapter(
              child: _MenuCard(
                items: [
                  _AccountMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Thông tin cá nhân',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.accountProfile),
                  ),
                  _AccountMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Địa chỉ giao hàng',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.selectAddress),
                  ),
                  _AccountMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn hàng của tôi',
                    onTap: () => _openRouteSafely(context, AppRoutes.orders),
                  ),
                  _AccountMenuItem(
                    icon: Icons.medical_services_outlined,
                    title: 'Đơn thuốc của tôi',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.prescriptions),
                  ),
                  _AccountMenuItem(
                    icon: Icons.payments_outlined,
                    title: 'Lịch sử thanh toán',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.paymentHistory),
                  ),
                  _AccountMenuItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Sản phẩm yêu thích',
                    onTap: () => _openRouteSafely(context, AppRoutes.favorites),
                  ),
                  _AccountMenuItem(
                    icon: Icons.history_rounded,
                    title: 'Thuốc thường dùng',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.frequentProducts),
                  ),
                  _AccountMenuItem(
                    icon: Icons.alarm_rounded,
                    title: 'Nhắc uống thuốc',
                    onTap: () => _openRouteSafely(context, AppRoutes.reminders),
                  ),
                  _AccountMenuItem(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Sức khỏe gia đình',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.healthTools),
                  ),
                  _AccountMenuItem(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Điểm thưởng & hạng thành viên',
                    onTap: () => _openRouteSafely(context, AppRoutes.loyalty),
                  ),
                  _AccountMenuItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Đánh giá của tôi',
                    onTap: () => _openRouteSafely(context, AppRoutes.myReviews),
                  ),
                  _AccountMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Trung tâm trợ giúp',
                    onTap: () => _openRouteSafely(context, AppRoutes.helpCenter),
                  ),
                  _AccountMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Thông báo',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.notifications),
                  ),
                  _AccountMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt',
                    onTap: () =>
                        _openRouteSafely(context, AppRoutes.appSettings),
                  ),
                  _AccountMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    isDestructive: true,
                    showChevron: false,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _readContact(String? email, String? phone) {
    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail;
    }

    final normalizedPhone = phone?.trim();
    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      return normalizedPhone;
    }

    return 'Chưa cập nhật thông tin';
  }

  static void _openRouteSafely(BuildContext context, String routeName) {
    if (_availableRoutes.contains(routeName)) {
      Navigator.of(context).pushNamed(routeName);
      return;
    }

    _openDevelopingFeature(context);
  }

  static void _openDevelopingFeature(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
    if (!context.mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}

class _GuestAccountScreen extends StatelessWidget {
  const _GuestAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: _AccountHeader(
              displayName: 'Khách hàng',
              contact: 'Chưa cập nhật thông tin',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.primaryBlue,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Vui lòng đăng nhập để xem và cập nhật thông tin cá nhân.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.login);
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.displayName,
    required this.contact,
    this.avatarUrl,
  });

  final String displayName;
  final String contact;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 24,
        24,
        28,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          _Avatar(avatarUrl: avatarUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFDCEBFF)),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Thành viên An Tâm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatarUrl?.trim();

    return CircleAvatar(
      radius: 34,
      backgroundColor: Colors.white,
      child: imageUrl == null || imageUrl.isEmpty
          ? const Icon(
              Icons.person_rounded,
              color: AppTheme.primaryBlue,
              size: 42,
            )
          : ClipOval(
              child: Image.network(
                imageUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryBlue,
                  size: 42,
                ),
              ),
            ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_AccountMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    final iconColor = isDestructive ? AppTheme.error : AppTheme.primaryBlue;

    return ListTile(
      minLeadingWidth: 28,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      trailing: showChevron
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            )
          : null,
      onTap: onTap,
    );
  }
}
