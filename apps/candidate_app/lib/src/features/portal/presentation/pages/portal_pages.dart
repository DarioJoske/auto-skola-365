import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/candidate_portal.dart';
import '../cubit/portal_cubit.dart';
import '../widgets/lesson_card.dart';
import '../widgets/request_lesson_dialog.dart';

final class PortalContent extends StatelessWidget {
  const PortalContent({required this.builder, super.key});
  final Widget Function(BuildContext, CandidatePortal) builder;
  @override
  Widget build(BuildContext context) => BlocBuilder<PortalCubit, PortalState>(
    builder: (context, state) {
      if (state.data == null && (state.loading || state.loadFailure == null)) {
        return const AppLoadingState();
      }
      return RefreshIndicator(
        onRefresh: () => context.read<PortalCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.loading) ...[
                    const AppLoadingState(isRefreshing: true),
                    const SizedBox(height: 16),
                  ],
                  if (state.loadFailure != null) ...[
                    AppInlineError(
                      message: state.loadFailure!.message,
                      onRetry: () => context.read<PortalCubit>().load(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.data != null)
                    KeyedSubtree(
                      key: const ValueKey('portal-data'),
                      child: builder(context, state.data!),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

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
              final next = _NextLesson(
                lesson: upcoming.firstOrNull,
                canRequest: data.canRequestLesson,
              );
              final progress = _HoursCard(data: data);
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

final class _NextLesson extends StatelessWidget {
  const _NextLesson({required this.lesson, required this.canRequest});
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

final class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.data});
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

final class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});
  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  bool _history = false;
  @override
  Widget build(BuildContext context) => PortalContent(
    builder: (context, data) {
      final items = _history
          ? data.historyAt(DateTime.now())
          : data.upcomingAt(DateTime.now());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Tvoji termini',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              FilledButton.icon(
                onPressed: data.canRequestLesson
                    ? () => showLessonRequest(context)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Zatraži termin'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Nadolazeći')),
                ButtonSegment(value: true, label: Text('Povijest')),
              ],
              selected: {_history},
              onSelectionChanged: (values) =>
                  setState(() => _history = values.single),
            ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            AppEmptyState(
              title: _history
                  ? 'Još nema povijesti vožnji'
                  : 'Nema nadolazećih termina',
              message: 'Ovdje ćeš vidjeti svoje termine i njihov status.',
            ),
          for (final item in items) ...[
            LessonCard(lesson: item),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

final class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => PortalContent(
    builder: (context, data) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Moj profil', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        AppCard(
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
              Text(context.read<AuthCubit>().state.user?.email ?? ''),
              const Divider(height: 32),
              Text(data.schoolName),
              const SizedBox(height: 8),
              Text('${data.categoryCode} kategorija'),
              const SizedBox(height: 8),
              Text(
                'Instruktor: ${data.instructorName ?? 'Još nije dodijeljen'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Odjavi se'),
          ),
        ),
      ],
    ),
  );
}
