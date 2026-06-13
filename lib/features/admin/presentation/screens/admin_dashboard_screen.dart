import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_dashboard_model.dart';
import '../../data/models/order_status_statistic_model.dart';
import '../../data/models/revenue_statistic_model.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../widgets/admin_empty_view.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _didStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (!(authProvider.currentUser?.isAdmin ?? false)) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        return;
      }

      context.read<AdminDashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan Admin')),
      body: Consumer<AdminDashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.overview == null) {
            return const AppLoading(message: 'Đang tải tổng quan Admin...');
          }

          if (provider.errorMessage != null && provider.overview == null) {
            return _DashboardErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadDashboard,
            );
          }

          final overview = provider.overview;
          if (overview == null) {
            return _DashboardErrorView(
              message: 'Chưa có dữ liệu tổng quan.',
              onRetry: provider.loadDashboard,
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: provider.loadDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'Xin chào, Quản trị viên',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Theo dõi nhanh hoạt động vận hành của An Tâm Pharma.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (provider.isLoading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppTheme.primaryBlue,
                  ),
                ],
                const SizedBox(height: 18),
                _StatisticsGrid(overview: overview),
                const SizedBox(height: 22),
                const _QuickActions(),
                const SizedBox(height: 10),
                const _CategoryShortcutCard(),
                const SizedBox(height: 22),
                _SectionHeader(title: 'Trạng thái đơn hàng'),
                const SizedBox(height: 10),
                _OrderStatusList(statistics: provider.orderStatusStatistics),
                const SizedBox(height: 22),
                _SectionHeader(title: 'Doanh thu 7 ngày'),
                const SizedBox(height: 10),
                _RevenueList(statistics: provider.revenueStatistics),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Truy cập nhanh'),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.lightBlue,
              child: Icon(
                Icons.local_offer_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
            title: const Text(
              'Quản lý voucher',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Tạo và quản lý mã khuyến mãi'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminVouchers),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.lightBlue,
              child: Icon(
                Icons.people_alt_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
            title: const Text(
              'Người dùng',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Khóa tài khoản, gán vai trò và quản lý người dùng',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminUsers),
          ),
        ),
      ],
    );
  }
}

class _CategoryShortcutCard extends StatelessWidget {
  const _CategoryShortcutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppTheme.lightBlue,
          child: Icon(Icons.category_rounded, color: AppTheme.primaryBlue),
        ),
        title: const Text(
          'Danh mục',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Thêm, sửa và quản lý danh mục sản phẩm'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCategories),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.overview});

  final AdminDashboardModel overview;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _AdminStatItem(
        label: 'Người dùng',
        value: overview.totalUsers.toString(),
        icon: Icons.people_alt_rounded,
      ),
      _AdminStatItem(
        label: 'Sản phẩm',
        value: overview.totalProducts.toString(),
        icon: Icons.medication_rounded,
      ),
      _AdminStatItem(
        label: 'Đơn hàng',
        value: overview.totalOrders.toString(),
        icon: Icons.receipt_long_rounded,
      ),
      _AdminStatItem(
        label: 'Đơn chờ xác nhận',
        value: overview.totalPendingOrders.toString(),
        icon: Icons.pending_actions_rounded,
      ),
      _AdminStatItem(
        label: 'Đơn đã giao',
        value: overview.totalDeliveredOrders.toString(),
        icon: Icons.local_shipping_rounded,
      ),
      _AdminStatItem(
        label: 'Đơn thuốc chờ duyệt',
        value: overview.totalPendingPrescriptions.toString(),
        icon: Icons.description_rounded,
      ),
      _AdminStatItem(
        label: 'Nhà thuốc',
        value: overview.totalPharmacies.toString(),
        icon: Icons.local_pharmacy_rounded,
      ),
      _AdminStatItem(
        label: 'Doanh thu',
        value: CurrencyFormatter.format(overview.totalRevenue),
        icon: Icons.payments_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = stats[index];
        return AdminStatCard(
          title: item.label,
          value: item.value,
          icon: item.icon,
        );
      },
    );
  }
}

class _OrderStatusList extends StatelessWidget {
  const _OrderStatusList({required this.statistics});

  final List<OrderStatusStatisticModel> statistics;

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return const _EmptySection(
        message: 'Chưa có dữ liệu trạng thái đơn hàng.',
        icon: Icons.receipt_long_rounded,
      );
    }

    return Column(
      children: statistics
          .map(
            (item) => _InfoRowCard(
              leadingIcon: Icons.receipt_long_rounded,
              title: item.statusLabel.isNotEmpty
                  ? item.statusLabel
                  : item.status,
              trailing: item.count.toString(),
            ),
          )
          .toList(),
    );
  }
}

class _RevenueList extends StatelessWidget {
  const _RevenueList({required this.statistics});

  final List<RevenueStatisticModel> statistics;

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return const _EmptySection(
        message: 'Chưa có dữ liệu doanh thu 7 ngày.',
        icon: Icons.payments_rounded,
      );
    }

    return Column(
      children: statistics
          .map(
            (item) => _InfoRowCard(
              leadingIcon: Icons.payments_rounded,
              title: item.label,
              subtitle: '${item.orderCount} đơn hàng',
              trailing: CurrencyFormatter.format(item.revenue),
            ),
          )
          .toList(),
    );
  }
}

class _InfoRowCard extends StatelessWidget {
  const _InfoRowCard({
    required this.leadingIcon,
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightBlue,
          child: Icon(leadingIcon, color: AppTheme.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Text(
          trailing,
          style: const TextStyle(
            color: AppTheme.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  const _DashboardErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: AdminEmptyView(message: message, icon: icon),
    );
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
    );
  }
}

class _AdminStatItem {
  const _AdminStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
