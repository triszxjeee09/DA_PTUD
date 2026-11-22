import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/json_api.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../favorite/providers/favorite_provider.dart';
import '../../../health/providers/health_provider.dart';
import '../../../reminder/providers/reminder_provider.dart';

/// Cài đặt: trạng thái kết nối API, đồng bộ dữ liệu SQLite cục bộ và thông tin ứng dụng.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _apiStatus;
  bool _checking = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _checkApi();
  }

  Future<void> _checkApi() async {
    setState(() => _checking = true);
    try {
      await JsonApi().get('/support/info');
      _apiStatus = 'Kết nối thành công';
    } catch (error) {
      _apiStatus = 'Không kết nối được: ${JsonApi.message(error)}';
    }
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  Future<void> _syncNow() async {
    final owner = context.read<AuthProvider>().currentUser?.id;
    if (owner == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final reminders = context.read<ReminderProvider>();
    final health = context.read<HealthProvider>();
    final favorites = context.read<FavoriteProvider>();
    setState(() => _syncing = true);
    await Future.wait([
      reminders.load(owner),
      health.load(owner),
      favorites.load(owner),
    ]);
    if (!mounted) {
      return;
    }
    setState(() => _syncing = false);
    final online = reminders.isOnline && health.isOnline;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          online
              ? 'Đã đồng bộ dữ liệu'
              : 'Chưa thể đồng bộ, dữ liệu vẫn được lưu trên máy',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.cloud_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Máy chủ API'),
                  subtitle: Text(
                    '${ApiConstants.baseUrl}\n${_checking ? 'Đang kiểm tra...' : (_apiStatus ?? '')}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    onPressed: _checking ? null : _checkApi,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.storage_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Dữ liệu ngoại tuyến (SQLite)'),
                  subtitle: const Text(
                    'Nhắc thuốc, hồ sơ sức khỏe và yêu thích được lưu trên máy và đồng bộ khi có mạng.',
                  ),
                  trailing: user == null
                      ? null
                      : FilledButton.tonal(
                          onPressed: _syncing ? null : _syncNow,
                          child: Text(_syncing ? 'Đang đồng bộ' : 'Đồng bộ'),
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Thông báo'),
                  subtitle: const Text(
                    'Nhắc thuốc, đơn hàng, tư vấn, khuyến mãi (Firebase Cloud Messaging)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Trung tâm trợ giúp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.helpCenter),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text('An Tâm Pharma'),
                  subtitle: Text(
                    'Thông tin thuốc chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ/dược sĩ.',
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
