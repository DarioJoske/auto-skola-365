import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../progress/domain/usecases/load_progress.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/usecases/cancel_instructor_lesson.dart';
import '../../domain/usecases/confirm_instructor_lesson.dart';
import '../../domain/usecases/complete_instructor_lesson.dart';
import '../../domain/usecases/get_instructor_lesson.dart';
import '../cubit/lesson_detail_cubit.dart';
import '../cubit/lesson_detail_state.dart';

String _statusLabel(String status) {
  return switch (status) {
    'REQUESTED' => 'Za potvrdu',
    'CONFIRMED' => 'Potvrdeno',
    'COMPLETED' => 'Odradeno',
    'CANCELLED' => 'Otkazano',
    'NO_SHOW' => 'Nije dosao',
    _ => status,
  };
}

String _createdByLabel(String createdByRole) {
  return switch (createdByRole) {
    'CANDIDATE' => 'Kandidat',
    'INSTRUCTOR' => 'Instruktor',
    'ADMIN' => 'Admin',
    _ => createdByRole,
  };
}

class LessonDetailPage extends StatelessWidget {
  const LessonDetailPage({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final membership = authState.instructorMembership;
        final accessToken = authState.accessToken;

        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (membership == null || accessToken == null) {
          return _DetailAccessError(
            onLogout: () => context.read<AuthCubit>().logout(),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ProgressCubit(
                loadProgress: getIt<LoadProgress>(),
                schoolId: membership.schoolId,
                accessToken: accessToken,
                resource: 'lessons',
                id: lessonId,
              )..load(),
            ),
            BlocProvider(
              create: (_) => LessonDetailCubit(
                completeInstructorLesson: getIt<CompleteInstructorLesson>(),
                getInstructorLesson: getIt<GetInstructorLesson>(),
                confirmInstructorLesson: getIt<ConfirmInstructorLesson>(),
                cancelInstructorLesson: getIt<CancelInstructorLesson>(),
                schoolId: membership.schoolId,
                accessToken: accessToken,
                lessonId: lessonId,
              )..load(),
            ),
          ],
          child: const LessonDetailView(),
        );
      },
    );
  }
}

class LessonDetailView extends StatelessWidget {
  const LessonDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LessonDetailCubit, LessonDetailState>(
      listenWhen: (previous, current) =>
          (previous.errorEventId != current.errorEventId &&
              current.errorMessage != null) ||
          (previous.successEventId != current.successEventId &&
              current.successMessage != null),
      listener: (context, state) {
        if (state.successMessage != null) {
          context.read<ProgressCubit>().load();
        }
        final message = state.errorStatusCode == 401
            ? 'Sesija je istekla. Prijavite se ponovno.'
            : state.successMessage ?? state.errorMessage;
        if (message == null) {
          return;
        }

        showAppSnackBar(context, message);
        if (state.errorStatusCode == 401) {
          context.read<AuthCubit>().logout();
        }
      },
      child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
        builder: (context, state) {
          final lesson = state.lesson;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _DetailHeader(
                onBack: () => context.pop(),
                onRefresh: () {
                  context.read<LessonDetailCubit>().load();
                  context.read<ProgressCubit>().load();
                },
              ),
              const SizedBox(height: 16),
              if (state.status == LessonDetailStatus.failure)
                AppInlineError(
                  message: state.errorMessage ?? 'Termin nije moguce ucitati.',
                  onRetry: () => context.read<LessonDetailCubit>().load(),
                ),
              if (state.isLoading)
                AppLoadingState(isRefreshing: lesson != null),
              if (lesson != null) ...[
                _LessonSummaryCard(lesson: lesson),
                const SizedBox(height: 12),
                _LessonActionsCard(lesson: lesson, state: state),
                const SizedBox(height: 12),
                const DrivingHoursPanel(),
                const SizedBox(height: 12),
                _LessonNotesCard(lesson: lesson),
                if (lesson.status == 'CONFIRMED') ...[
                  const SizedBox(height: 16),
                  _CompleteLessonForm(
                    key: ValueKey(lesson.id),
                    lesson: lesson,
                    busy: state.actionInProgress,
                  ),
                ],
                if (lesson.status == 'COMPLETED') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Bilješka nakon vožnje',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(lesson.completionNote ?? 'Nema bilješke.'),
                  if (lesson.completedAt != null)
                    Text(
                      'Evidentirano: ${_formatFullDate(lesson.completedAt!)} ${_formatTime(lesson.completedAt!)}',
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Natrag',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Detalji termina',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Osvjezi termin',
        ),
      ],
    );
  }
}

class _LessonSummaryCard extends StatelessWidget {
  const _LessonSummaryCard({required this.lesson});

  final InstructorLesson lesson;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusDot(status: lesson.status),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusLabel(lesson.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Kandidat',
              value: lesson.candidateName,
            ),
            _DetailRow(
              icon: Icons.directions_car_outlined,
              label: 'Kategorija',
              value: '${lesson.categoryName} (${lesson.categoryCode})',
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Vrijeme',
              value:
                  '${_formatFullDate(lesson.startAt)} · ${_formatTime(lesson.startAt)}-${_formatTime(lesson.endAt)}',
            ),
            _DetailRow(
              icon: Icons.event_note_outlined,
              label: 'Tip',
              value: lesson.lessonType,
            ),
            _DetailRow(
              icon: Icons.business_outlined,
              label: 'Poslovnica',
              value: lesson.branchName ?? 'Nije odabrana',
            ),
            _DetailRow(
              icon: Icons.how_to_reg_outlined,
              label: 'Rezervirao',
              value: _createdByLabel(lesson.createdByRole),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonActionsCard extends StatelessWidget {
  const _LessonActionsCard({required this.lesson, required this.state});

  final InstructorLesson lesson;
  final LessonDetailState state;

  @override
  Widget build(BuildContext context) {
    final canConfirm = lesson.status == 'REQUESTED';
    final canCancel =
        lesson.status == 'REQUESTED' || lesson.status == 'CONFIRMED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: !canConfirm || state.actionInProgress
              ? null
              : () => context.read<LessonDetailCubit>().confirmLesson(),
          icon: state.actionInProgress && canConfirm
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text('Prihvati termin'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: !canCancel || state.actionInProgress
              ? null
              : () async {
                  final confirmed = await showAppConfirmation(
                    context,
                    title: 'Otkazati termin?',
                    message:
                        'Termin će biti otkazan za kandidata i instruktora.',
                    confirmLabel: 'Otkaži termin',
                  );
                  if (!confirmed || !context.mounted) return;

                  await context.read<LessonDetailCubit>().cancelLesson();
                },
          icon: state.actionInProgress && canCancel
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cancel_outlined),
          label: const Text('Otkazi termin'),
        ),
      ],
    );
  }
}

class _LessonNotesCard extends StatelessWidget {
  const _LessonNotesCard({required this.lesson});

  final InstructorLesson lesson;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = lesson.notes?.trim();

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Napomene',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              notes == null || notes.isEmpty ? 'Nema napomena.' : notes,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: _statusColor(context, status),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DetailAccessError extends StatelessWidget {
  const _DetailAccessError({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: colorScheme.onErrorContainer),
                const SizedBox(height: 12),
                Text(
                  'Korisnik nema pristup detaljima termina.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Odjavi se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _statusColor(BuildContext context, String status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    'REQUESTED' => colors.tertiary,
    'CONFIRMED' => colors.primary,
    'CANCELLED' => colors.outline,
    'COMPLETED' => Colors.green.shade700,
    'NO_SHOW' => colors.error,
    _ => colors.secondary,
  };
}

String _formatFullDate(DateTime value) {
  return '${_weekdayLabel(value.weekday)}, ${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';
}

String _weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Ponedjeljak',
    DateTime.tuesday => 'Utorak',
    DateTime.wednesday => 'Srijeda',
    DateTime.thursday => 'Cetvrtak',
    DateTime.friday => 'Petak',
    DateTime.saturday => 'Subota',
    DateTime.sunday => 'Nedjelja',
    _ => '',
  };
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _CompleteLessonForm extends StatefulWidget {
  const _CompleteLessonForm({
    required this.lesson,
    required this.busy,
    super.key,
  });
  final InstructorLesson lesson;
  final bool busy;

  @override
  State<_CompleteLessonForm> createState() => _CompleteLessonFormState();
}

class _CompleteLessonFormState extends State<_CompleteLessonForm> {
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEnded = !widget.lesson.endAt.isAfter(DateTime.now());
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _note,
            enabled: !widget.busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Bilješka nakon vožnje (neobavezno)',
              hintText: 'Dodatna napomena o vožnji',
            ),
            validator: (value) => (value?.length ?? 0) > 2000
                ? 'Bilješka može sadržavati najviše 2000 znakova.'
                : null,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: widget.busy || !hasEnded
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      context.read<LessonDetailCubit>().completeLesson(
                        _note.text.trim(),
                      );
                    }
                  },
            icon: const Icon(Icons.task_alt),
            label: Text(widget.busy ? 'Spremanje…' : 'Dovrši vožnju'),
          ),
          if (!hasEnded)
            const Text(
              'Sat možete završiti nakon isteka termina. Tada osvježite prikaz.',
            ),
        ],
      ),
    );
  }
}
