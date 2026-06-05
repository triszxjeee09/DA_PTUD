import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status, this.label});

  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.trim().toUpperCase();
    final chipLabel = _readLabel(normalizedStatus, label);
    final color = _readColor(normalizedStatus);

    return Chip(
      label: Text(chipLabel),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.18)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }

  String _readLabel(String normalizedStatus, String? customLabel) {
    final text = customLabel?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }

    return switch (normalizedStatus) {
      'ACTIVE' => 'Đang hoạt động',
      'INACTIVE' => 'Ngừng hoạt động',
      'BLOCKED' => 'Đã khóa',
      'PENDING' => 'Chờ xử lý',
      'APPROVED' => 'Đã duyệt',
      'REJECTED' => 'Từ chối',
      'DELIVERED' => 'Đã giao',
      'CANCELLED' => 'Đã hủy',
      'PAID' => 'Đã thanh toán',
      'FAILED' => 'Thất bại',
      _ => status,
    };
  }

  Color _readColor(String normalizedStatus) {
    return switch (normalizedStatus) {
      'ACTIVE' || 'APPROVED' || 'DELIVERED' || 'PAID' => AppTheme.success,
      'PENDING' => AppTheme.warning,
      'BLOCKED' || 'REJECTED' || 'CANCELLED' || 'FAILED' => AppTheme.error,
      'INACTIVE' => AppTheme.textSecondary,
      _ => AppTheme.primaryBlue,
    };
  }
}
