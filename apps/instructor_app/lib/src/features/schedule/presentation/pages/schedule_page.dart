import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/usecases/cancel_instructor_lesson.dart';
import '../../domain/usecases/confirm_instructor_lesson.dart';
import '../../domain/usecases/list_instructor_lessons.dart';
import '../cubit/schedule_cubit.dart';
import '../cubit/schedule_state.dart';

const _lessonStatuses = ['REQUESTED', 'CONFIRMED', 'CANCELLED'];

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

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

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
          return _ScheduleAccessError(
            onLogout: () => context.read<AuthCubit>().logout(),
          );
        }

        return BlocProvider(
          create: (_) => ScheduleCubit(
            listInstructorLessons: getIt<ListInstructorLessons>(),
            confirmInstructorLesson: getIt<ConfirmInstructorLesson>(),
            cancelInstructorLesson: getIt<CancelInstructorLesson>(),
            schoolId: membership.schoolId,
            accessToken: accessToken,
          )..load(),
          child: const ScheduleView(),
        );
      },
    );
  }
}

class _ScheduleAccessError extends StatelessWidget {
  const _ScheduleAccessError({required this.onLogout});

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
                  'Korisnik nema pristup instruktorskom rasporedu.',
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

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final CalendarController _calendarController = CalendarController();

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && context.mounted) {
      await context.read<ScheduleCubit>().selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleCubit, ScheduleState>(
      listenWhen: (previous, current) =>
          (previous.errorEventId != current.errorEventId &&
              current.errorMessage != null) ||
          (previous.successEventId != current.successEventId &&
              current.successMessage != null),
      listener: (context, state) {
        final message = state.successMessage ?? state.errorMessage;
        if (message == null) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        if (state.errorStatusCode == 401) {
          context.read<AuthCubit>().logout();
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return BlocBuilder<ScheduleCubit, ScheduleState>(
            builder: (context, state) {
              _calendarController.displayDate = state.selectedDate;
              _calendarController.view = switch (state.rangeMode) {
                ScheduleRangeMode.day => CalendarView.day,
                ScheduleRangeMode.week => CalendarView.week,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        _ScheduleHeader(
                          selectedDate: state.selectedDate,
                          rangeMode: state.rangeMode,
                          instructorName: authState.user?.fullName,
                          onPreviousDay: () =>
                              context.read<ScheduleCubit>().moveByDays(-1),
                          onNextDay: () =>
                              context.read<ScheduleCubit>().moveByDays(1),
                          onRefresh: () => context.read<ScheduleCubit>().load(),
                          onPickDate: () =>
                              _pickDate(context, state.selectedDate),
                        ),
                        const SizedBox(height: 16),
                        _ScheduleFilters(
                          status: state.filters.status,
                          rangeMode: state.rangeMode,
                        ),
                        const SizedBox(height: 12),
                        _LessonsOverview(
                          lessons: state.lessons,
                          rangeMode: state.rangeMode,
                          actionLessonId: state.actionLessonId,
                          onLessonTap: (lesson) =>
                              _openLessonDetail(context, lesson),
                          onLessonAction: (lesson) =>
                              _showLessonActions(context, lesson),
                        ),
                        const SizedBox(height: 12),
                        if (state.status == ScheduleStatus.failure)
                          _InlineError(
                            message:
                                state.errorMessage ??
                                'Raspored nije moguce ucitati.',
                            onRetry: () => context.read<ScheduleCubit>().load(),
                          )
                        else if (state.lessons.isEmpty && !state.isLoading)
                          _EmptySchedule(
                            hasActiveFilter: state.filters.status != null,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Stack(
                      children: [
                        SfCalendar(
                          controller: _calendarController,
                          view: switch (state.rangeMode) {
                            ScheduleRangeMode.day => CalendarView.day,
                            ScheduleRangeMode.week => CalendarView.week,
                          },
                          dataSource: _InstructorLessonsDataSource(
                            context: context,
                            lessons: state.lessons,
                          ),
                          onTap: (details) {
                            final appointment =
                                details.appointments?.firstOrNull;
                            if (appointment is! Appointment) {
                              return;
                            }
                            final lesson = state.lessons.firstWhere(
                              (lesson) => lesson.id == appointment.id,
                            );
                            _openLessonDetail(context, lesson);
                          },
                          onViewChanged: (details) {
                            final nextDate = _dateFromVisibleRange(
                              details.visibleDates,
                              state.rangeMode,
                            );
                            if (nextDate == null ||
                                _sameDate(nextDate, state.filters.from)) {
                              return;
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                context.read<ScheduleCubit>().selectDate(
                                  nextDate,
                                );
                              }
                            });
                          },
                          firstDayOfWeek: 1,
                          headerHeight: 0,
                          viewHeaderHeight: 0,
                          todayHighlightColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          appointmentBuilder: (context, details) {
                            final appointment =
                                details.appointments.firstOrNull;
                            if (appointment is! Appointment) {
                              return const SizedBox.shrink();
                            }

                            final lesson = state.lessons.firstWhere(
                              (lesson) => lesson.id == appointment.id,
                            );
                            return _CalendarLessonTile(lesson: lesson);
                          },
                          timeSlotViewSettings: const TimeSlotViewSettings(
                            startHour: 7,
                            endHour: 21,
                            timeInterval: Duration(minutes: 60),
                            timeIntervalHeight: 88,
                            timeRulerSize: 64,
                            timeFormat: 'HH:mm',
                          ),
                        ),
                        if (state.isLoading)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x33FFFFFF),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _focusLesson(InstructorLesson lesson) {
    _calendarController.displayDate = lesson.startAt;
    _calendarController.selectedDate = lesson.startAt;
  }

  Future<void> _openLessonDetail(
    BuildContext context,
    InstructorLesson lesson,
  ) async {
    _focusLesson(lesson);
    await context.push('/lessons/${lesson.id}');
    if (context.mounted) {
      await context.read<ScheduleCubit>().load();
    }
  }

  Future<void> _showLessonActions(
    BuildContext context,
    InstructorLesson lesson,
  ) {
    _focusLesson(lesson);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ScheduleCubit>(),
        child: _LessonActionsSheet(lesson: lesson),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.selectedDate,
    required this.rangeMode,
    required this.instructorName,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onRefresh,
    required this.onPickDate,
  });

  final DateTime selectedDate;
  final ScheduleRangeMode rangeMode;
  final String? instructorName;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onRefresh;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dnevni raspored',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (instructorName != null) ...[
          const SizedBox(height: 4),
          Text(
            instructorName!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPreviousDay,
              icon: const Icon(Icons.chevron_left),
              tooltip: rangeMode == ScheduleRangeMode.day
                  ? 'Prethodni dan'
                  : 'Prethodni tjedan',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(_formatRangeLabel(selectedDate, rangeMode)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onNextDay,
              icon: const Icon(Icons.chevron_right),
              tooltip: rangeMode == ScheduleRangeMode.day
                  ? 'Sljedeci dan'
                  : 'Sljedeci tjedan',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Osvjezi raspored',
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleFilters extends StatelessWidget {
  const _ScheduleFilters({required this.status, required this.rangeMode});

  final String? status;
  final ScheduleRangeMode rangeMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ScheduleRangeMode>(
          segments: const [
            ButtonSegment(
              value: ScheduleRangeMode.day,
              icon: Icon(Icons.calendar_view_day),
              label: Text('Dan'),
            ),
            ButtonSegment(
              value: ScheduleRangeMode.week,
              icon: Icon(Icons.calendar_view_week),
              label: Text('Tjedan'),
            ),
          ],
          selected: {rangeMode},
          onSelectionChanged: (selection) =>
              context.read<ScheduleCubit>().setRangeMode(selection.first),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(Icons.filter_alt_outlined),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Svi statusi')),
            ..._lessonStatuses.map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(_statusLabel(status)),
              ),
            ),
          ],
          onChanged: (value) =>
              context.read<ScheduleCubit>().filterStatus(value),
        ),
      ],
    );
  }
}

class _LessonsOverview extends StatelessWidget {
  const _LessonsOverview({
    required this.lessons,
    required this.rangeMode,
    required this.actionLessonId,
    required this.onLessonTap,
    required this.onLessonAction,
  });

  final List<InstructorLesson> lessons;
  final ScheduleRangeMode rangeMode;
  final String? actionLessonId;
  final ValueChanged<InstructorLesson> onLessonTap;
  final ValueChanged<InstructorLesson> onLessonAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = rangeMode == ScheduleRangeMode.day
        ? 'Termini za dan'
        : 'Termini za tjedan';

    return SizedBox(
      height: lessons.isEmpty ? 0 : 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '$title (${lessons.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return _LessonOverviewTile(
                  lesson: lesson,
                  isBusy: actionLessonId == lesson.id,
                  onTap: () => onLessonTap(lesson),
                  onAction: () => onLessonAction(lesson),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonOverviewTile extends StatelessWidget {
  const _LessonOverviewTile({
    required this.lesson,
    required this.isBusy,
    required this.onTap,
    required this.onAction,
  });

  final InstructorLesson lesson;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final color = _calendarStatusColor(context, lesson.status);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 228,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          onLongPress: onAction,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lesson.candidateName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isBusy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onAction,
                        icon: const Icon(Icons.more_horiz),
                        tooltip: 'Akcije termina',
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${_shortDate(lesson.startAt)} · ${_formatTime(lesson.startAt)}-${_formatTime(lesson.endAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_statusLabel(lesson.status)} · ${lesson.categoryCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarLessonTile extends StatelessWidget {
  const _CalendarLessonTile({required this.lesson});

  final InstructorLesson lesson;

  @override
  Widget build(BuildContext context) {
    final color = _calendarStatusColor(context, lesson.status);
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final isCompact = height < 42;

        return Container(
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.only(right: 6, bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 10,
            vertical: isCompact ? 2 : 7,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRect(
            child: DefaultTextStyle(
              style: TextStyle(
                color: foreground,
                height: 1.08,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lesson.candidateName,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${_formatTime(lesson.startAt)}-${_formatTime(lesson.endAt)} · ${_statusLabel(lesson.status)}',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kategorija ${lesson.categoryCode}',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.86),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LessonActionsSheet extends StatelessWidget {
  const _LessonActionsSheet({required this.lesson});

  final InstructorLesson lesson;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final isBusy = state.actionLessonId == lesson.id;
        final canConfirm = lesson.status == 'REQUESTED';
        final canCancel =
            lesson.status == 'REQUESTED' || lesson.status == 'CONFIRMED';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lesson.candidateName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatFullDate(lesson.startAt)} · ${_formatTime(lesson.startAt)}-${_formatTime(lesson.endAt)}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_statusLabel(lesson.status)} · Kategorija ${lesson.categoryCode}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: !canConfirm || isBusy
                      ? null
                      : () => _runAction(
                          context,
                          context.read<ScheduleCubit>().confirmLesson(
                            lesson.id,
                          ),
                        ),
                  icon: isBusy && canConfirm
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
                  onPressed: !canCancel || isBusy
                      ? null
                      : () => _runAction(
                          context,
                          context.read<ScheduleCubit>().cancelLesson(lesson.id),
                        ),
                  icon: isBusy && canCancel
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Otkazi termin'),
                ),
                if (!canConfirm && !canCancel) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Termin je vec otkazan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAction(BuildContext context, Future<bool> action) async {
    final navigator = Navigator.of(context);
    final completed = await action;
    if (completed) {
      navigator.pop();
    }
  }
}

class _InstructorLessonsDataSource extends CalendarDataSource {
  _InstructorLessonsDataSource({
    required BuildContext context,
    required List<InstructorLesson> lessons,
  }) {
    appointments = lessons
        .map(
          (lesson) => Appointment(
            id: lesson.id,
            startTime: lesson.startAt,
            endTime: lesson.endAt,
            subject: '${lesson.candidateName} · ${_statusLabel(lesson.status)}',
            notes: lesson.notes,
            color: _calendarStatusColor(context, lesson.status),
          ),
        )
        .toList();
  }
}

Color _calendarStatusColor(BuildContext context, String status) {
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

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.hasActiveFilter});

  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_available_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasActiveFilter
                    ? 'Nema termina za odabrani status.'
                    : 'Nema termina za odabrani dan.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokusaj ponovno'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatFullDate(DateTime value) {
  return '${_weekdayLabel(value.weekday)}, ${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';
}

String _formatRangeLabel(DateTime selectedDate, ScheduleRangeMode rangeMode) {
  if (rangeMode == ScheduleRangeMode.day) {
    return _formatFullDate(selectedDate);
  }

  final from = _weekStart(selectedDate);
  final to = from.add(const Duration(days: 6));
  return '${_shortDate(from)} - ${_shortDate(to)}';
}

DateTime? _dateFromVisibleRange(
  List<DateTime> visibleDates,
  ScheduleRangeMode rangeMode,
) {
  if (visibleDates.isEmpty) {
    return null;
  }

  final visibleDate = visibleDates.first;
  final date = DateTime(visibleDate.year, visibleDate.month, visibleDate.day);
  return switch (rangeMode) {
    ScheduleRangeMode.day => date,
    ScheduleRangeMode.week => _weekStart(date),
  };
}

bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

DateTime _weekStart(DateTime value) {
  final day = DateTime(value.year, value.month, value.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String _shortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.';
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
