import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/guest_model.dart';

class GuestRoleChip extends StatelessWidget {
  final GuestRole role;
  const GuestRoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role == GuestRole.padrino
        ? AppColors.padrino
        : role == GuestRole.vip
            ? AppColors.vip
            : AppColors.regular;

    final label = role == GuestRole.padrino
        ? '✨ Padrino'
        : role == GuestRole.vip
            ? '⭐ VIP'
            : 'Regular';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
