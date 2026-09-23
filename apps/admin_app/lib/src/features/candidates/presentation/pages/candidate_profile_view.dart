import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../lessons/presentation/pages/lesson_presentation.dart';
import '../../../progress/domain/usecases/load_progress.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../domain/entities/candidate.dart';
import '../cubit/candidate_profile_cubit.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';
import 'candidate_dialog.dart';
import 'candidate_presentation.dart';

final class CandidateProfileView extends StatefulWidget {
  const CandidateProfileView({super.key});
  @override
  State<CandidateProfileView> createState() => _CandidateProfileViewState();
}

final class _CandidateProfileViewState extends State<CandidateProfileView> {
  int _tab = 0;
  Future<void> _edit(Candidate candidate) async {
    final candidates = context.read<CandidatesCubit>();
    final token = context.read<AuthCubit>().state.accessToken!;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: candidates),
          BlocProvider(
            create: (_) => ProgressCubit(
              loadProgress: getIt<LoadProgress>(),
              schoolId: candidate.schoolId,
              accessToken: token,
              resource: 'candidates',
              id: candidate.id,
            )..load(),
          ),
        ],
        child: CandidateDialog(candidate: candidate),
      ),
    );
    if (saved == true && mounted) {
      context.read<CandidateProfileCubit>().load();
      candidates.load();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CandidateProfileCubit, CandidateProfileState>(
    listenWhen: (previous, current) => previous.eventId != current.eventId,
    listener: (context, state) {
      if (state.failure?.statusCode == 401) {
        showSessionExpired(context);
        context.read<AuthCubit>().logout();
      }
    },
    builder: (context, state) {
      final candidate = state.candidate;
      return ListView(
        children: [
          BlocConsumer<CandidatesCubit, CandidatesState>(
            listenWhen: (previous, current) =>
                previous.errorEventId != current.errorEventId &&
                current.status == CandidatesStatus.failure,
            listener: (context, state) {
              if (state.errorStatusCode == 401 &&
                  ModalRoute.of(context)?.isCurrent == true) {
                showSessionExpired(context);
                context.read<AuthCubit>().logout();
              }
            },
            builder: (context, state) =>
                state.status == CandidatesStatus.failure
                ? AppInlineError(
                    message:
                        state.errorMessage ??
                        'Učitavanje podataka upisa nije uspjelo.',
                    onRetry: () => context.read<CandidatesCubit>().load(),
                  )
                : const SizedBox.shrink(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/candidates'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kandidati'),
            ),
          ),
          if (candidate != null) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: AppSpacing.md,
              spacing: AppSpacing.lg,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.fullName,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'Kandidati / Profil · ${candidate.categoryCode} kategorija',
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(candidate),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Uredi kandidata'),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go(
                        Uri(
                          path: '/lessons/new',
                          queryParameters: {
                            'candidateId': candidate.id,
                            if (candidate.assignedInstructorId != null)
                              'instructorId': candidate.assignedInstructorId!,
                          },
                        ).toString(),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Dogovori vožnju'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _ProfileSummary(candidate: candidate),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (index, label) in [
                  'Vožnje',
                  'Dokumenti',
                  'Uplate',
                  'Poruke',
                ].indexed)
                  FilledButton.tonal(
                    onPressed: () => setState(() => _tab = index),
                    style: index == _tab
                        ? FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          )
                        : null,
                    child: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (state.loading) const AppLoadingState(isRefreshing: true),
          if (state.failure != null)
            AppInlineError(
              message: state.failure!.message,
              onRetry: () => context.read<CandidateProfileCubit>().load(),
            ),
          if (candidate != null && _tab == 0) _DrivingHistory(state: state),
          if (candidate != null && _tab != 0)
            AppEmptyState(
              title:
                  '${['Vožnje', 'Dokumenti', 'Uplate', 'Poruke'][_tab]} nisu dostupni',
              message:
                  'Ovaj modul još nije implementiran. Podaci se trenutačno ne vode u aplikaciji.',
            ),
        ],
      );
    },
  );
}

final class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.candidate});
  final Candidate candidate;
  @override
  Widget build(BuildContext context) {
    final completed = candidate.completedDrivingHours;
    final target = candidate.requiredDrivingHours;
    final progress = AppProgressCard(
      title:
          '${candidate.fullName.toUpperCase()} · ${candidate.categoryCode} KATEGORIJA',
      valueLabel: completed == null
          ? '—'
          : target == null
          ? '$completed'
          : '$completed / $target',
      subtitle: 'evidentiranih školskih sati',
      message:
          'Instruktor: ${candidate.assignedInstructorName ?? 'Nije dodijeljen'}${target == null ? '\nCilj sati nije postavljen.' : ''}',
      progress: completed != null && target != null && target > 0
          ? completed / target
          : null,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Kontaktni e-mail: ${candidate.email ?? 'Nije unesen'}'),
              Text('Telefon: ${candidate.phone ?? 'Nije unesen'}'),
              Text('OIB: ${candidate.oib ?? 'Nije unesen'}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStatusBadge(
                label: candidateStatusLabel(candidate.status),
                tone: candidateStatusTone(candidate.status),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                candidate.hasLogin
                    ? 'E-mail za prijavu: ${candidate.loginEmail ?? 'Nije dostupan'}'
                    : 'Kandidatski pristup nije aktiviran.',
              ),
              if (candidate.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Interna napomena: ${candidate.notes}'),
              ],
            ],
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 850
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 358, child: progress),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                progress,
                const SizedBox(height: AppSpacing.lg),
                details,
              ],
            ),
    );
  }
}

final class _DrivingHistory extends StatelessWidget {
  const _DrivingHistory({required this.state});
  final CandidateProfileState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        children: [
          Text(
            'Vožnje i bilješke',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Prethodni mjesec',
                onPressed: () => context.read<CandidateProfileCubit>().load(
                  month: DateTime(state.month.year, state.month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${state.month.month}. ${state.month.year}.'),
              IconButton(
                tooltip: 'Sljedeći mjesec',
                onPressed: () => context.read<CandidateProfileCubit>().load(
                  month: DateTime(state.month.year, state.month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      if (state.lessons.isEmpty && !state.loading && state.failure == null)
        const AppEmptyState(
          title: 'Nema vožnji u ovom mjesecu',
          message: 'Odaberite drugi mjesec ili dogovorite novu vožnju.',
        ),
      if (state.lessons.isNotEmpty)
        AppCard(
          showBorder: false,
          child: LayoutBuilder(
            builder: (context, constraints) => AppHorizontalScroll(
              minWidth: constraints.maxWidth,
              child: SizedBox(
                width: constraints.maxWidth < 920 ? 920 : constraints.maxWidth,
                child: Column(
                  children: [
                    for (final lesson in state.lessons)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${formatDate(lesson.startAt.toLocal())}\n${formatTime(lesson.startAt.toLocal())} – ${formatTime(lesson.endAt.toLocal())}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                lesson.status == 'COMPLETED'
                                    ? '1 sat · ${lesson.categoryCode}'
                                    : '${lesson.endAt.difference(lesson.startAt).inMinutes} min · ${lesson.categoryCode}',
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(lesson.instructorName),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                [lesson.notes, lesson.completionNote]
                                        .whereType<String>()
                                        .where((note) => note.isNotEmpty)
                                        .join(' · ')
                                        .isEmpty
                                    ? 'Bez bilješke'
                                    : [lesson.notes, lesson.completionNote]
                                          .whereType<String>()
                                          .where((note) => note.isNotEmpty)
                                          .join(' · '),
                              ),
                            ),
                            AppStatusBadge(
                              label: lessonStatusLabel(lesson.status),
                              tone: lessonStatusTone(lesson.status),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      const Text(
        'Fond sati obuhvaća dovršene vožnje aktualne kategorije kroz sva razdoblja. Dosezanje cilja nije potvrda spremnosti za ispit.',
      ),
    ],
  );
}
