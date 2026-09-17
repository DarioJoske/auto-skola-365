import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../domain/entities/candidate_portal.dart';
import '../utils/lesson_formatters.dart';
import 'request_lesson_dialog.dart';

final class NextLessonCard extends StatelessWidget {
  const NextLessonCard({
    required this.lesson,
    required this.canRequest,
    super.key,
  });
  final CandidateLesson? lesson;
  final bool canRequest;
  @override
  Widget build(BuildContext context) {
    final item = lesson;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DrivingSchoolTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SLJEDEĆA VOŽNJA',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                item == null
                    ? 'Spreman za novu vožnju?'
                    : lessonDate(context, item.startAt),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              if (item != null) ...[
                Text(
                  '${lessonTime(context, item.startAt)} – ${lessonTime(context, item.endAt)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text('${item.instructorName} · ${item.statusLabel}'),
              ] else
                Text(
                  canRequest
                      ? 'Odaberi termin koji ti odgovara.'
                      : 'Autoškola će ti dodijeliti instruktora.',
                ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: canRequest ? () => showLessonRequest(context) : null,
                icon: const Icon(Icons.add),
                label: const Text('Zatraži termin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
