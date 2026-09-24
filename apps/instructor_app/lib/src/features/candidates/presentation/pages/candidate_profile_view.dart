import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/work_page_header.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import '../../../schedule/presentation/widgets/instructor_lesson_card.dart';
import '../../../schedule/presentation/widgets/reserve_lesson_button.dart';
import '../cubit/candidate_profile_cubit.dart';

final class CandidateProfileView extends StatelessWidget {
  const CandidateProfileView({super.key});
  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<CandidateProfileCubit>().load(),
      context.read<ProgressCubit>().load(),
    ]);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<CandidateProfileCubit, CandidateProfileState>(
    listenWhen: (a, b) => a.eventId != b.eventId,
    listener: (context, state) {
      if (state.failure?.statusCode == 401) {
        showSessionExpired(context);
        context.read<AuthCubit>().logout();
      }
    },
    child: BlocBuilder<CandidateProfileCubit, CandidateProfileState>(
      builder: (context, state) {
        return AppPage(
          maxWidth: 720,
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.lessons.length + 1,
              itemBuilder: (context, index) {
                if (index > 0) {
                  final lesson = state.lessons[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppListItem(
                      leading: CircleAvatar(
                        child: Text('${lesson.startAt.toLocal().day}'),
                      ),
                      title:
                          '${lessonDate(lesson.startAt)} · ${lessonTime(lesson.startAt)}',
                      subtitle:
                          '${lessonStatus(lesson.status)} · ${lesson.categoryCode} kategorija${lesson.completionNote == null ? '' : '\nInterna bilješka: ${lesson.completionNote}'}',
                      onTap: () async {
                        await context.push('/lessons/${lesson.id}');
                        if (context.mounted) _refresh(context);
                      },
                    ),
                  );
                }
                return _CandidateSummary(
                  state: state,
                  onRefresh: () => _refresh(context),
                );
              },
            ),
          ),
        );
      },
    ),
  );
}

class _CandidateSummary extends StatelessWidget {
  const _CandidateSummary({required this.state, required this.onRefresh});
  final CandidateProfileState state;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    final candidate = state.candidate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkPageHeader(
          title: candidate?.fullName ?? 'Profil kandidata',
          subtitle: candidate == null
              ? null
              : '${candidate.categoryCode} kategorija',
          backPath: '/candidates',
          onRefresh: () => onRefresh(),
        ),
        if (state.loading) AppLoadingState(isRefreshing: candidate != null),
        if (state.failure != null)
          AppInlineError(
            message: state.failure!.message,
            onRetry: () => onRefresh(),
          ),
        if (candidate != null) ...[
          const DrivingHoursPanel(emphasized: true),
          const SizedBox(height: 16),
          ReserveLessonButton(
            candidateId: candidate.id,
            onSaved: () => onRefresh(),
          ),
          const SizedBox(height: 24),
          if (candidate.phone != null || candidate.email != null) ...[
            AppListItem(
              title: 'Kontakt',
              subtitle: [
                candidate.phone,
                candidate.email,
              ].whereType<String>().join('\n'),
            ),
            const SizedBox(height: 16),
          ],
          if (candidate.notes?.isNotEmpty == true) ...[
            AppListItem(
              title: 'Interna bilješka kandidata',
              subtitle: candidate.notes!,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Vaše vožnje s kandidatom',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sati uključuju sve dovršene vožnje trenutačne kategorije. Ovdje su prikazani samo vaši termini.',
          ),
          const SizedBox(height: 16),
          if (state.lessons.isEmpty && !state.loading && state.failure == null)
            const AppEmptyState(
              title: 'Još nema vožnji',
              message: 'Dogovorite prvi termin s kandidatom.',
            ),
        ],
      ],
    );
  }
}
