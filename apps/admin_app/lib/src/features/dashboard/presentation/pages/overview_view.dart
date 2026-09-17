import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/school_overview.dart';
import '../cubit/school_overview_cubit.dart';
import '../cubit/school_overview_state.dart';

final class OverviewView extends StatelessWidget {
  const OverviewView({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SchoolOverviewCubit, SchoolOverviewState>(
    listenWhen: (previous, current) =>
        previous.errorEventId != current.errorEventId,
    listener: (context, state) {
      if (state.failure?.statusCode == 401) {
        showSessionExpired(context);
        context.read<AuthCubit>().logout();
      }
    },
    builder: (context, state) => ListView(
      children: [
        const _Header(),
        const SizedBox(height: 24),
        if (state.isLoading) AppLoadingState(isRefreshing: state.data != null),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppInlineError(
              message: state.failure!.message,
              onRetry: context.read<SchoolOverviewCubit>().load,
            ),
          ),
        if (state.data case final data?) ...[
          _Welcome(data: data),
          const SizedBox(height: 24),
          _Metrics(data: data),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final lessons = _LessonSection(
                title: 'Danas na cesti',
                lessons: data.todayLessons,
                emptyMessage: 'Danas nema termina.',
                showDate: false,
              );
              final attention = _Attention(data: data);
              if (constraints.maxWidth < 1000 ||
                  MediaQuery.textScalerOf(context).scale(16) > 24) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [lessons, const SizedBox(height: 24), attention],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: lessons),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: attention),
                ],
              );
            },
          ),
        ],
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 16,
    runSpacing: 12,
    children: [
      Text('Pregled škole', style: Theme.of(context).textTheme.headlineLarge),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          IconButton(
            tooltip: 'Osvježi pregled',
            onPressed: context.read<SchoolOverviewCubit>().load,
            icon: const Icon(Icons.refresh),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/lessons'),
            icon: const Icon(Icons.calendar_month),
            label: const Text('Otvori raspored'),
          ),
        ],
      ),
    ],
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.data});
  final SchoolOverview data;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.inverseSurface,
      showBorder: false,
      radius: 28,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.date} · ${data.timeZone}',
                  style: TextStyle(color: colors.onInverseSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mirniji raspored.\nViše dobrih vožnji.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onInverseSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Danas ${data.confirmedToday} potvrđenih i ${data.completedToday} završenih termina.',
                  style: TextStyle(color: colors.onInverseSurface),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 800)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Icon(Icons.route, size: 96, color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});
  final SchoolOverview data;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 4
          : constraints.maxWidth >= 550
          ? 2
          : 1;
      final cards = [
        AppStatCard(
          label: 'Aktivni kandidati',
          value: '${data.activeCandidates}',
          detail:
              'Trenutno: od upisa do zakazanog ispita; bez leadova, položenih, odustalih i arhiviranih.',
        ),
        AppStatCard(
          label: 'Termini danas',
          value: '${data.todayLessons.length}',
          detail: 'Početak danas · svi statusi, uključujući otkazane.',
        ),
        AppStatCard(
          label: 'Otvoreni zahtjevi',
          value: '${data.pendingRequests}',
          detail: 'Svi termini sa statusom zahtjeva, bez ograničenja datuma.',
        ),
        AppStatCard(
          label: 'Čeka završetak',
          value: '${data.overdueLessons}',
          detail: 'Potvrđeni termini čije je vrijeme završetka prošlo.',
        ),
      ];
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final card in cards)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 16) / columns,
              child: card,
            ),
        ],
      );
    },
  );
}

class _Attention extends StatelessWidget {
  const _Attention({required this.data});
  final SchoolOverview data;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Treba tvoju pažnju', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data.unassignedActiveCandidates} aktivnih kandidata bez instruktora',
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/candidates?withoutInstructor=true'),
              child: const Text('Dodijeli instruktora'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _LessonSection(
        title: 'Zahtjevi · ${data.pendingRequests}',
        lessons: data.requests,
        emptyMessage: 'Nema otvorenih zahtjeva.',
        showDate: true,
      ),
      const SizedBox(height: 16),
      _LessonSection(
        title: 'Čeka završetak · ${data.overdueLessons}',
        lessons: data.overdue,
        emptyMessage: 'Nema termina koji čekaju završetak.',
        showDate: true,
      ),
      if (data.pendingRequests > 5 || data.overdueLessons > 5)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Prikazano je do 5 najstarijih termina po skupini. Nakon obrade osvježi pregled.',
          ),
        ),
    ],
  );
}

class _LessonSection extends StatelessWidget {
  const _LessonSection({
    required this.title,
    required this.lessons,
    required this.emptyMessage,
    required this.showDate,
  });
  final String title, emptyMessage;
  final List<OverviewLesson> lessons;
  final bool showDate;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (lessons.isEmpty) Text(emptyMessage),
        for (final lesson in lessons)
          _LessonRow(lesson: lesson, showDate: showDate),
      ],
    ),
  );
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.showDate});
  final OverviewLesson lesson;
  final bool showDate;
  @override
  Widget build(BuildContext context) {
    final status = switch (lesson.status) {
      'REQUESTED' => 'Zahtjev',
      'CONFIRMED' => 'Potvrđeno',
      'COMPLETED' => 'Završeno',
      'CANCELLED' => 'Otkazano',
      'NO_SHOW' => 'Nedolazak',
      _ => lesson.status,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${showDate ? '${lesson.date} · ' : ''}${lesson.time} · $status',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text('${lesson.candidateName} · ${lesson.categoryCode}'),
          Text('Instruktor: ${lesson.instructorName}'),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/lessons',
                    queryParameters: {
                      'date': lesson.startAt,
                      'candidateId': lesson.candidateId,
                      'instructorId': lesson.instructorId,
                    },
                  ).toString(),
                ),
                child: const Text('Termin'),
              ),
              TextButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/candidates',
                    queryParameters: {'query': lesson.candidateName},
                  ).toString(),
                ),
                child: const Text('Kandidat'),
              ),
              TextButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/instructors',
                    queryParameters: {'query': lesson.instructorName},
                  ).toString(),
                ),
                child: const Text('Instruktor'),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
