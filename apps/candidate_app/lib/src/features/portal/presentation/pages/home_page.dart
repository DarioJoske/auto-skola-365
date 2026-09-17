import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../widgets/portal_content.dart';
import '../widgets/next_lesson_card.dart';
import '../widgets/driving_hours_card.dart';
import '../widgets/lesson_card.dart';

final class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => PortalContent(
    builder: (context, data) {
      final upcoming = data.upcomingAt(DateTime.now());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data.schoolName.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bok, ${data.firstName}.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text('Tvoj put do vozačke, korak po korak.'),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final next = NextLessonCard(
                lesson: upcoming.firstOrNull,
                canRequest: data.canRequestLesson,
              );
              final progress = DrivingHoursCard(data: data);
              if (constraints.maxWidth >= 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: next),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: progress),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [next, const SizedBox(height: 16), progress],
              );
            },
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            children: [
              Text(
                'Tvoji termini',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => context.go('/lessons'),
                child: const Text('Prikaži sve'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const AppEmptyState(
              title: 'Raspored je još prazan',
              message:
                  'Pošalji zahtjev za termin ili se dogovori s instruktorom.',
            ),
          for (final lesson in upcoming.take(3)) ...[
            LessonCard(lesson: lesson),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}
