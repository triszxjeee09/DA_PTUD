import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

enum _NotificationFilter {
  all('Tất cả', null),
  order('Đơn hàng', 'ORDER'),
  prescription('Đơn thuốc', 'PRESCRIPTION'),
  promotion('Khuyến mãi', 'PROMOTION'),
  system('Hệ thống', 'SYSTEM');

  const _NotificationFilter(this.label, this.type);

  final String label;
  final String? type;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final ScrollController _scrollController;

  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<NotificationProvider>();
      provider.loadNotifications(refresh: true);
      provider.loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      final provider = context.read<NotificationProvider>();
      if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
        provider.loadNotifications();
      }
    }
  }

  Future<void> _refresh() async {
    final provider = context.read<NotificationProvider>();
    await Future.wait([
      provider.loadNotifications(refresh: true),
      provider.loadUnreadCount(),
    ]);
  }

  Future<void> _markAllAsRead() async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.markAllAsRead();

    if (!mounted || success) {
      return;
    }

    _showSnackBar(provider.errorMessage ?? 'Không thể đánh dấu đã đọc');
  }

  Future<void> _openNotification(NotificationModel notification) async {
    final provider = context.read<NotificationProvider>();
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    if (!mounted) {
      return;
    }

    final referenceId = notification.referenceId;
    switch (notification.type) {
      case 'ORDER':
      case 'PAYMENT':
        if (referenceId != null && referenceId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.orderDetail,
            arguments: {'orderId': referenceId},
          );
          return;
        }
        break;
      case 'PRESCRIPTION':
        if (referenceId != null && referenceId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.prescriptionDetail,
            arguments: {'id': referenceId},
          );
          return;
        }
        break;
      case 'PROMOTION':
        Navigator.of(context).pushNamed(AppRoutes.vouchers);
        return;
      case 'STOCK':
        if (referenceId != null && referenceId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.productDetail,
            arguments: {'id': referenceId},
          );
          return;
        }
        break;
      case 'MEDICATION_REMINDER':
        Navigator.of(context).pushNamed(AppRoutes.reminders);
        return;
      case 'CONSULTATION':
        Navigator.of(context).pushNamed(AppRoutes.chat, arguments: {'tab': 1});
        return;
      case 'LOYALTY':
        Navigator.of(context).pushNamed(AppRoutes.loyalty);
        return;
      case 'SUPPORT':
        if (referenceId != null && referenceId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.supportTicketDetail,
            arguments: {'ticketId': referenceId},
          );
          return;
        }
        break;
      case 'SYSTEM':
        _showDetailDialog(notification);
        return;
      default:
        break;
    }

    _showDetailDialog(notification);
  }

  void _showDetailDialog(NotificationModel notification) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notification.title),
          content: Text(notification.content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final filteredNotifications = _filterNotifications(provider.notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đọc tất cả',
            onPressed: provider.notifications.isEmpty ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(selected: _selectedFilter, onSelected: _selectFilter),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(provider, filteredNotifications),
            ),
          ),
        ],
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    final type = _selectedFilter.type;
    if (type == null) {
      return notifications;
    }

    return notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  void _selectFilter(_NotificationFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() => _selectedFilter = filter);
  }

  Widget _buildBody(
    NotificationProvider provider,
    List<NotificationModel> notifications,
  ) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const AppLoading(message: 'Đang tải thông báo...');
    }

    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return _NotificationErrorView(
        message: provider.errorMessage!,
        onRetry: _refresh,
      );
    }

    if (provider.notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: const [
          AppEmptyState(
            title: 'Bạn chưa có thông báo nào',
            icon: Icons.notifications_none_outlined,
          ),
        ],
      );
    }

    if (notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: const [
          AppEmptyState(
            title: 'Không có thông báo phù hợp',
            icon: Icons.filter_alt_off_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: notifications.length + (provider.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notification = notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () => _openNotification(notification),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _NotificationFilter.values.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: filter == selected,
                onSelected: (_) => onSelected(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(notification.type);
    final isUnread = !notification.isRead;

    return Card(
      color: isUnread ? AppTheme.lightBlue.withValues(alpha: 0.55) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(_notificationIcon(notification.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _notificationIcon(String type) {
    return switch (type) {
      'ORDER' => Icons.receipt_long_outlined,
      'PRESCRIPTION' => Icons.description_outlined,
      'PROMOTION' => Icons.card_giftcard_outlined,
      'SYSTEM' => Icons.info_outline,
      _ => Icons.notifications_none_outlined,
    };
  }

  Color _notificationColor(String type) {
    return switch (type) {
      'ORDER' => AppTheme.primaryBlue,
      'PRESCRIPTION' => AppTheme.warning,
      'PROMOTION' => AppTheme.success,
      'SYSTEM' => AppTheme.textSecondary,
      _ => AppTheme.primaryBlue,
    };
  }
}

class _NotificationErrorView extends StatelessWidget {
  const _NotificationErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: AppTheme.primaryBlue,
          size: 72,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: () {
            onRetry();
          },
          child: const Text('Thử lại'),
        ),
      ],
    );
  }
}

String _formatTime(DateTime? value) {
  if (value == null) {
    return 'Đang cập nhật';
  }

  return DateFormatter.formatDateTime(value);
}
