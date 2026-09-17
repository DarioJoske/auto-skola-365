import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../domain/entities/candidate_portal.dart';

final class ProfileDetailsCard extends StatelessWidget {
  const ProfileDetailsCard({
    required this.data,
    required this.email,
    super.key,
  });
  final CandidatePortal data;
  final String email;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          child: Text(data.firstName.isEmpty ? '?' : data.firstName[0]),
        ),
        const SizedBox(height: 16),
        Text(
          '${data.firstName} ${data.lastName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(email),
        const Divider(height: 32),
        Text(data.schoolName),
        const SizedBox(height: 8),
        Text('${data.categoryCode} kategorija'),
        const SizedBox(height: 8),
        Text('Instruktor: ${data.instructorName ?? 'Još nije dodijeljen'}'),
      ],
    ),
  );
}
