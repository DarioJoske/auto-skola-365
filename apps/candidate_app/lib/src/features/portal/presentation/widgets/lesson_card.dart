import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/portal_cubit.dart';
import '../cubit/portal_state.dart';
import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../domain/entities/candidate_portal.dart';
import '../utils/lesson_formatters.dart';

final class LessonCard extends StatelessWidget {
  const LessonCard({required this.lesson, super.key});
  final CandidateLesson lesson;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              lessonDate(context, lesson.startAt),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppStatusBadge(
              label: lesson.statusLabel,
              isPositive:
                  lesson.status == 'CONFIRMED' || lesson.status == 'COMPLETED',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${lessonTime(context, lesson.startAt)} – ${lessonTime(context, lesson.endAt)}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Instruktor: ${lesson.instructorName}'),
        if (lesson.branchName != null) Text(lesson.branchName!),
        if (lesson.proposedStartAt case final proposed?) ...[
          const SizedBox(height: 16),
          Text(
            'Instruktor predlaže: ${lessonDate(context, proposed)} · ${lessonTime(context, proposed)} (60 minuta)',
          ),
          const Text(
            'Prihvaćanje potvrđuje vožnju ako je termin još dostupan.',
          ),
          BlocBuilder<PortalCubit, PortalState>(
            builder: (context, state) => Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: state.saving
                      ? null
                      : () => context.read<PortalCubit>().respondProposal(
                          lesson.id,
                          proposed,
                          true,
                        ),
                  child: const Text('Prihvati prijedlog'),
                ),
                TextButton(
                  onPressed: state.saving
                      ? null
                      : () => context.read<PortalCubit>().respondProposal(
                          lesson.id,
                          proposed,
                          false,
                        ),
                  child: const Text('Odbij prijedlog'),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
