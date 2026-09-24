import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/work_page_header.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/daily_schedule_cubit.dart';
import '../widgets/instructor_lesson_card.dart';

final class DailyScheduleView extends StatelessWidget {
  const DailyScheduleView({super.key});
  Future<void> _open(BuildContext context, String id) async {
    await context.push('/lessons/$id');
    if (context.mounted) context.read<DailyScheduleCubit>().load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<DailyScheduleCubit, DailyScheduleState>(
        listenWhen: (a, b) => a.eventId != b.eventId,
        listener: (context, state) {
          if (state.failure?.statusCode == 401) {
            showSessionExpired(context);
            context.read<AuthCubit>().logout();
          }
        },
        child: BlocBuilder<DailyScheduleCubit, DailyScheduleState>(
          builder: (context, state) {
            final next = state.nextLesson;
            final rest = state.today
                .where((lesson) => lesson.id != next?.id)
                .toList();
            final later = state.upcoming
                .where(
                  (lesson) =>
                      lesson.id != next?.id && !state.today.contains(lesson),
                )
                .toList();
            final rows = [...rest, ...later];
            return AppPage(
              maxWidth: 720,
              child: RefreshIndicator(
                onRefresh: context.read<DailyScheduleCubit>().load,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: rows.length + 1,
                  itemBuilder: (context, index) {
                    if (index > 0) {
                      final lesson = rows[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InstructorLessonCard(
                          lesson: lesson,
                          showDate: true,
                          onTap: () => _open(context, lesson.id),
                        ),
                      );
                    }
                    return _DailyOverview(
                      state: state,
                      hasRows: rows.isNotEmpty,
                      onOpen: (id) => _open(context, id),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
}

String _lessonCountLabel(int count) {
  if (count % 100 >= 11 && count % 100 <= 14) return 'vožnji';
  return switch (count % 10) {
    1 => 'vožnja',
    2 || 3 || 4 => 'vožnje',
    _ => 'vožnji',
  };
}

class _DailyOverview extends StatelessWidget {
  const _DailyOverview({
    required this.state,
    required this.hasRows,
    required this.onOpen,
  });
  final DailyScheduleState state;
  final bool hasRows;
  final void Function(String) onOpen;
  @override
  Widget build(BuildContext context) {
    final next = state.nextLesson;
    final name = context.read<AuthCubit>().state.user?.firstName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkPageHeader(
          title: name == null ? 'Dobar dan.' : 'Dobar dan, $name.',
          subtitle: lessonDate(state.now),
          onRefresh: () => context.read<DailyScheduleCubit>().load(),
        ),
        if (state.loading)
          AppLoadingState(isRefreshing: state.lessons.isNotEmpty),
        if (state.failure != null)
          AppInlineError(
            message: state.failure!.message,
            onRetry: () => context.read<DailyScheduleCubit>().load(),
          ),
        if ((!state.loading && state.failure == null) ||
            state.lessons.isNotEmpty) ...[
          AppStatCard(
            label: 'DANAS',
            value:
                '${state.today.where((lesson) => ['CONFIRMED', 'COMPLETED'].contains(lesson.status)).length} ${_lessonCountLabel(state.today.where((lesson) => ['CONFIRMED', 'COMPLETED'].contains(lesson.status)).length)}',
            detail:
                '${state.today.where((lesson) => lesson.status == 'COMPLETED').length} održano · ${state.today.where((lesson) => lesson.status == 'REQUESTED').length} za potvrdu',
          ),
          const SizedBox(height: 16),
          if (next != null) ...[
            Text(
              'Sljedeća vožnja',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            InstructorLessonCard(
              lesson: next,
              showDate: true,
              action: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onOpen(next.id),
                  child: const Text('Otvori vožnju'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.requests.isNotEmpty) ...[
            AppListItem(
              leading: CircleAvatar(child: Text('${state.requests.length}')),
              title: 'Zahtjevi za termin',
              subtitle: 'Čekaju potvrdu · sljedećih 7 dana',
            ),
            const SizedBox(height: 8),
            ...state.requests.map(
              (lesson) => TextButton(
                onPressed: () => onOpen(lesson.id),
                child: Text(
                  '${lesson.candidateName} · ${lessonDate(lesson.startAt)} ${lessonTime(lesson.startAt)}',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.lessons.isEmpty && state.failure == null)
            const AppEmptyState(
              title: 'Nema vožnji u sljedećih 7 dana',
              message:
                  'Otvorite raspored za ostale datume ili rezervaciju termina.',
            ),
          if (hasRows) ...[
            Text(
              'Danas i nadolazeće vožnje',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}
