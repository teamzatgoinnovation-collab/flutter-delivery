import 'package:flutter/material.dart';

import '../models/delivery_models.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final StopStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StopStatus.assigned => ('Assigned', const Color(0xFF64748B)),
      StopStatus.accepted => ('Accepted', const Color(0xFF0EA5E9)),
      StopStatus.rejected => ('Rejected', const Color(0xFFB91C1C)),
      StopStatus.reachedRestaurant => ('At restaurant', const Color(0xFF7C3AED)),
      StopStatus.pickedUp => ('Picked up', const Color(0xFFD97706)),
      StopStatus.outForDelivery => ('Out for delivery', const Color(0xFF2563EB)),
      StopStatus.delivered => ('Delivered', const Color(0xFF15803D)),
      StopStatus.failed => ('Failed', const Color(0xFFB91C1C)),
      StopStatus.cancelled => ('Cancelled', const Color(0xFF78716C)),
      StopStatus.returned => ('Returned', const Color(0xFFC2410C)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
