import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/lesson.dart';
import 'lesson_presentation.dart';

final class LessonWeekBoard extends StatelessWidget {
  const LessonWeekBoard({
    required this.from,
    required this.lessons,
    required this.onOpen,
    this.showWeekend = false,
    super.key,
  });

  final DateTime from;
  final List<Lesson> lessons;
  final ValueChanged<Lesson> onOpen;
  final bool showWeekend;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final days = showWeekend ? 7 : 5;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final width = constraints.maxWidth < 600
          ? constraints.maxWidth
          : ((constraints.maxWidth - 64) / 5).clamp(
              210.0 * scale,
              400.0 * scale,
            );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(days, (index) {
            final date = DateTime(from.year, from.month, from.day + index);
            final next = DateTime(date.year, date.month, date.day + 1);
            final daily =
                lessons
                    .where(
                      (lesson) =>
                          lesson.startAt.isBefore(next) &&
                          lesson.endAt.isAfter(date),
                    )
                    .toList()
                  ..sort((a, b) => a.startAt.compareTo(b.startAt));
            return Padding(
              padding: EdgeInsets.only(right: index == days - 1 ? 0 : 16),
              child: SizedBox(
                width: width,
                child: _DayColumn(date: date, lessons: daily, onOpen: onOpen),
              ),
            );
          }),
        ),
      );
    },
  );
}

final class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.lessons,
    required this.onOpen,
  });
  final DateTime date;
  final List<Lesson> lessons;
  final ValueChanged<Lesson> onOpen;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(date, DateTime.now());
    const days = ['PON', 'UTO', 'SRI', 'ČET', 'PET', 'SUB', 'NED'];
    return AppCard(
      padding: const EdgeInsets.all(12),
      showBorder: false,
      color: today ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${days[date.weekday - 1]} · ${date.day}.',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: today
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nema termina'),
            ),
          for (var index = 0; index < lessons.length; index++) ...[
            if (index > 0) const SizedBox(height: 16),
            _LessonCard(lesson: lessons[index], onOpen: onOpen),
          ],
        ],
      ),
    );
  }
}

final class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onOpen});
  final Lesson lesson;
  final ValueChanged<Lesson> onOpen;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
    child: AppCard(
      key: ValueKey(lesson.id),
      radius: 12,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.primaryContainer,
      showBorder: false,
      onTap: () => onOpen(lesson),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${formatTime(lesson.startAt)} – ${formatTime(lesson.endAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.candidateName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lesson.instructorName} · ${lesson.categoryCode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          AppStatusBadge(
            label: lessonStatusLabel(lesson.status),
            tone: lessonStatusTone(lesson.status),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
