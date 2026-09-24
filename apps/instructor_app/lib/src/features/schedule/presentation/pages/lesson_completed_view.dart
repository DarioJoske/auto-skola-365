import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/work_page_header.dart';
import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import '../cubit/lesson_detail_cubit.dart';
import '../cubit/lesson_detail_state.dart';
import '../widgets/instructor_lesson_card.dart';
import '../widgets/lesson_action_listener.dart';

final class LessonCompletedView extends StatelessWidget {
  const LessonCompletedView({super.key});
  @override
  Widget build(BuildContext context) => LessonActionListener(
    child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
      builder: (context, state) {
        final lesson = state.lesson;
        final completed = lesson?.status == 'COMPLETED';
        return AppPage(
          maxWidth: 720,
          child: ListView(
            children: [
              WorkPageHeader(
                title: completed ? 'Sat je evidentiran.' : 'Evidencija sata',
                subtitle: lesson == null
                    ? null
                    : '${lesson.candidateName} · ${lessonDate(lesson.startAt)}, ${lessonTime(lesson.startAt)}',
                backPath: '/home',
              ),
              if (state.isLoading) const AppLoadingState(),
              if (state.status == LessonDetailStatus.failure)
                AppInlineError(
                  message:
                      state.errorMessage ?? 'Evidenciju nije moguće učitati.',
                  onRetry: () => context.read<LessonDetailCubit>().load(),
                ),
              if (lesson != null && !completed)
                AppInlineError(
                  message: 'Ovaj sat nije zaključen.',
                  onRetry: () => context.read<LessonDetailCubit>().load(),
                ),
              if (completed) ...[
                AppCard(
                  color: Theme.of(
                    context,
                  ).extension<AppSemanticColors>()?.successContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Vožnja je uspješno zaključena.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sati u nastavku prikazuju aktualnu evidenciju kandidata. Interna bilješka nije vidljiva kandidatu.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () =>
                            context.push('/candidates/${lesson!.candidateId}'),
                        child: const Text('Profil kandidata'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const DrivingHoursPanel(),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Na današnji raspored'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
