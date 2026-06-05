import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class SelectAddressScreen extends StatelessWidget {
  const SelectAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Chọn địa chỉ')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppTheme.primaryBlue,
                size: 72,
              ),
              SizedBox(height: 16),
              Text(
                'Chọn địa chỉ giao hàng',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'Màn hình chọn địa chỉ sẽ được hoàn thiện ở bước tiếp theo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
