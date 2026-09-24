import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/instructor_lesson.dart';

String lessonTime(DateTime value) =>
    '${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
String lessonDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day}. ${date.month}. ${date.year}.';
}

String lessonStatus(String status) => switch (status) {
  'REQUESTED' => 'Za potvrdu',
  'CONFIRMED' => 'Potvrđeno',
  'COMPLETED' => 'Održano',
  'CANCELLED' => 'Otkazano',
  'NO_SHOW' => 'Nije došao',
  _ => status,
};

final class InstructorLessonCard extends StatelessWidget {
  const InstructorLessonCard({
    required this.lesson,
    this.onTap,
    this.showDate = false,
    this.action,
    super.key,
  });
  final InstructorLesson lesson;
  final VoidCallback? onTap;
  final bool showDate;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppLessonCard(
    timeLabel:
        '${showDate ? '${lessonDate(lesson.startAt)} · ' : ''}${lessonTime(lesson.startAt)} – ${lessonTime(lesson.endAt)}',
    title: lesson.candidateName,
    details:
        '${lesson.categoryCode} kategorija · ${lesson.lessonType == 'DRIVING' ? 'Vožnja' : lesson.lessonType}',
    statusLabel: lessonStatus(lesson.status),
    statusTone: switch (lesson.status) {
      'CONFIRMED' => AppTone.success,
      'REQUESTED' => AppTone.warning,
      _ => AppTone.neutral,
    },
    location: lesson.branchName == null
        ? null
        : 'Poslovnica: ${lesson.branchName}',
    onTap: onTap,
    action: action,
  );
}
