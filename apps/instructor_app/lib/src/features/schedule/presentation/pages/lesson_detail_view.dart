import '../../domain/entities/instructor_lesson.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/work_page_header.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import '../cubit/lesson_detail_cubit.dart';
import '../cubit/lesson_detail_state.dart';
import '../widgets/instructor_lesson_card.dart';
import '../widgets/lesson_action_listener.dart';

final class LessonDetailView extends StatelessWidget {
  const LessonDetailView({super.key});
  Future<void> _open(BuildContext context, String path) async {
    await context.push(path);
    if (!context.mounted) return;
    context.read<LessonDetailCubit>().load();
    context.read<ProgressCubit>().load();
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Otkazati termin?'),
        content: const Text('Termin će biti označen kao otkazan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Otkaži termin'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LessonDetailCubit>().cancelLesson();
    }
  }

  @override
  Widget build(BuildContext context) => LessonActionListener(
    onSuccess: (context, state) {
      showAppSnackBar(context, state.successMessage!);
      context.read<ProgressCubit>().load();
    },
    child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
      builder: (context, state) {
        final lesson = state.lesson;
        return AppPage(
          maxWidth: 720,
          child: ListView(
            children: [
              WorkPageHeader(
                title: 'Detalj vožnje',
                subtitle: lesson == null ? null : lessonDate(lesson.startAt),
                backPath: '/home',
                onRefresh: () {
                  context.read<LessonDetailCubit>().load();
                  context.read<ProgressCubit>().load();
                },
              ),
              if (state.isLoading)
                AppLoadingState(isRefreshing: lesson != null),
              if (state.status == LessonDetailStatus.failure)
                AppInlineError(
                  message: state.errorMessage ?? 'Vožnju nije moguće učitati.',
                  onRetry: () => context.read<LessonDetailCubit>().load(),
                ),
              if (lesson != null) ...[
                InstructorLessonCard(lesson: lesson),
                const SizedBox(height: 16),
                const DrivingHoursPanel(),
                const SizedBox(height: 16),
                _LessonNotes(
                  lesson: lesson,
                  onProfile: () =>
                      _open(context, '/candidates/${lesson.candidateId}'),
                ),
                const SizedBox(height: 16),
                if (lesson.status == 'CONFIRMED' &&
                    lesson.lessonType == 'DRIVING') ...[
                  FilledButton(
                    onPressed: state.actionInProgress
                        ? null
                        : () =>
                              _open(context, '/lessons/${lesson.id}/complete'),
                    child: const Text('Završi sat'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Sat se može zaključiti nakon završetka termina.'),
                ],
                if (lesson.status == 'COMPLETED')
                  FilledButton(
                    onPressed: () =>
                        _open(context, '/lessons/${lesson.id}/completed'),
                    child: const Text('Pregled evidencije'),
                  ),
                if (lesson.status == 'REQUESTED')
                  FilledButton(
                    onPressed: state.actionInProgress
                        ? null
                        : () => _open(context, '/lessons/${lesson.id}/request'),
                    child: const Text('Obradi zahtjev'),
                  ),
                if (['REQUESTED', 'CONFIRMED'].contains(lesson.status))
                  TextButton(
                    onPressed: state.actionInProgress
                        ? null
                        : () => _cancel(context),
                    child: const Text('Otkaži termin'),
                  ),
                if (state.actionInProgress) const LinearProgressIndicator(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );
}

class _LessonNotes extends StatelessWidget {
  const _LessonNotes({required this.lesson, required this.onProfile});
  final InstructorLesson lesson;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('INTERNA BILJEŠKA', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Text(lesson.notes ?? 'Nema bilješke uz termin.'),
        if (lesson.completionNote != null) ...[
          const SizedBox(height: 12),
          Text('Nakon vožnje: ${lesson.completionNote}'),
        ],
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: onProfile,
          child: const Text('Profil kandidata'),
        ),
      ],
    ),
  );
}
