import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AdminActionButton extends StatelessWidget {
  const AdminActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppTheme.primaryBlue;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}
