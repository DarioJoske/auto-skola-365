import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../domain/entities/candidate_portal.dart';

final class DrivingHoursCard extends StatelessWidget {
  const DrivingHoursCard({required this.data, super.key});
  final CandidatePortal data;
  @override
  Widget build(BuildContext context) {
    final target = data.requiredDrivingHours;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tvoj napredak', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${data.categoryCode} kategorija · praktična nastava'),
          const SizedBox(height: 28),
          Text(
            target == null
                ? '${data.completedDrivingHours} sati odrađeno'
                : '${data.completedDrivingHours}/$target sati odrađeno',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (target != null && target > 0)
            LinearProgressIndicator(
              value: (data.completedDrivingHours / target).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: 'Odrađeni sati',
              semanticsValue: '${data.completedDrivingHours} od $target',
            ),
          const SizedBox(height: 16),
          Text(
            target == null
                ? 'Cilj sati postavlja tvoja autoškola.'
                : 'Broje se samo dovršene vožnje.',
          ),
        ],
      ),
    );
  }
}
