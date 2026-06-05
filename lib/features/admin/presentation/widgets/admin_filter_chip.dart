import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? AppTheme.primaryBlue : AppTheme.lightBlue,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
