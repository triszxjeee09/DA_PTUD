import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../admin/presentation/screens/admin_prescription_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chat/presentation/screens/staff_chat_list_screen.dart';
import '../../../chat/providers/chat_provider.dart';
import '../../../review/presentation/screens/staff_review_reply_screen.dart';
import '../../../support/presentation/screens/support_ticket_screens.dart';

/// Giao diện cho dược sĩ: duyệt đơn thuốc, tư vấn khách, xử lý hỗ trợ, phản hồi đánh giá.
class PharmacistMainScreen extends StatefulWidget {
  const PharmacistMainScreen({super.key});

  @override
  State<PharmacistMainScreen> createState() => _PharmacistMainScreenState();
}

class _PharmacistMainScreenState extends State<PharmacistMainScreen> {
  int _index = 0;
  Timer? _presenceTimer;
  late final ChatProvider _chat;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _chat.setStaffPresence(online: true);
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _chat.setStaffPresence(online: true);
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _chat.setStaffPresence(online: false);
    super.dispose();
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await _chat.setStaffPresence(online: false);
    if (!mounted) {
      return;
    }
    await context.read<AuthProvider>().logout();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context
        .select<AuthProvider, ({bool allowed, String name, String email})>(
          (auth) => (
            allowed:
                (auth.currentUser?.isPharmacist ?? false) ||
                (auth.currentUser?.isAdmin ?? false),
            name: auth.currentUser?.fullName ?? 'Dược sĩ',
            email: auth.currentUser?.email ?? '',
          ),
        );
    final unread = context.select<ChatProvider, int>(
      (chat) => chat.staffUnreadTotal,
    );

    if (!user.allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dược sĩ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Bạn không có quyền truy cập khu vực dược sĩ.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
                  child: const Text('Đăng nhập tài khoản khác'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tabs = <Widget>[
      const AdminPrescriptionScreen(),
      Scaffold(
        appBar: AppBar(title: const Text('Tư vấn khách hàng')),
        body: const StaffChatListScreen(),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('Yêu cầu hỗ trợ')),
        body: const SupportTicketListScreen(staffMode: true, embedded: true),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('Phản hồi đánh giá')),
        body: const StaffReviewReplyScreen(),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lightBlue,
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${user.email}\nDược sĩ • đang trực tuyến'),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'Đơn thuốc',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.forum_outlined),
            ),
            label: 'Tư vấn',
          ),
          const NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            label: 'Hỗ trợ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.star_outline),
            label: 'Đánh giá',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
