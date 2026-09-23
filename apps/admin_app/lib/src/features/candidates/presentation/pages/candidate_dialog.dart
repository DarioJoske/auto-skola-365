import 'package:flutter/material.dart';
import '../../domain/entities/candidate.dart';
import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import '../widgets/candidate_form.dart';

final class CandidateDialog extends StatelessWidget {
  const CandidateDialog({this.candidate, super.key});
  final Candidate? candidate;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(candidate == null ? 'Novi kandidat' : 'Uredi kandidata'),
    content: SizedBox(
      width: 880,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (candidate != null) const DrivingHoursPanel(),
            CandidateForm(
              candidate: candidate,
              onSaved: (_) => Navigator.of(context).pop(true),
              onCancel: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
}
