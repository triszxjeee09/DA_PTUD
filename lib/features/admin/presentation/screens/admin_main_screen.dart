import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/require_admin.dart';
import 'admin_account_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_order_screen.dart';
import 'admin_product_screen.dart';
import 'admin_prescription_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RequireAdmin(child: AdminDashboardScreen()),
    RequireAdmin(child: AdminProductScreen()),
    RequireAdmin(child: AdminOrderScreen()),
    RequireAdmin(child: AdminPrescriptionScreen()),
    AdminAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.lightBlue,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            elevation: 0,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_rounded),
                label: 'Sản phẩm',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Đơn hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_rounded),
                label: 'Đơn thuốc',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
