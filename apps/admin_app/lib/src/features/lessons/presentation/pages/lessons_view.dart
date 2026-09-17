import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../instructors/domain/entities/instructor.dart';
import '../../domain/entities/lesson.dart';
import '../cubit/lessons_cubit.dart';
import '../cubit/lessons_state.dart';

import 'lesson_presentation.dart';
import 'lesson_dialog.dart';

enum _LessonDetailsAction { edit }

const _calendarViewOptions = [
  _CalendarViewOption('Dan', CalendarView.day),
  _CalendarViewOption('Tjedan', CalendarView.week),
  _CalendarViewOption('Radni tjedan', CalendarView.workWeek),
  _CalendarViewOption('Mjesec', CalendarView.month),
  _CalendarViewOption('Instruktori', CalendarView.timelineWeek),
];

class _CalendarViewOption {
  const _CalendarViewOption(this.label, this.view);

  final String label;
  final CalendarView view;
}

final class LessonsView extends StatefulWidget {
  const LessonsView({super.key});

  @override
  State<LessonsView> createState() => _LessonsViewState();
}

class _LessonsViewState extends State<LessonsView> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _calendarView = CalendarView.timelineWeek;

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = context
        .read<LessonsCubit>()
        .state
        .filters
        .from;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog(BuildContext context, DateTime startAt) async {
    final cubit = context.read<LessonsCubit>();
    await cubit.load();
    if (!context.mounted || cubit.state.status == LessonsStatus.failure) return;
    final state = cubit.state;
    if (state.candidates.isEmpty || state.instructors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dodaj barem jednog kandidata i instruktora.'),
        ),
      );
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LessonsCubit>(),
        child: LessonDialog(initialStartAt: startAt),
      ),
    );

    if (created == true && context.mounted) {
      await context.read<LessonsCubit>().load();
    }
  }

  Future<void> _openEditDialog(BuildContext context, Lesson lesson) async {
    final cubit = context.read<LessonsCubit>();
    await cubit.load();
    if (!context.mounted || cubit.state.status == LessonsStatus.failure) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LessonsCubit>(),
        child: LessonDialog(lesson: lesson),
      ),
    );

    if (updated == true && context.mounted) {
      await context.read<LessonsCubit>().load();
    }
  }

  Future<void> _openLessonDetails(BuildContext context, Lesson lesson) async {
    final action = await showDialog<_LessonDetailsAction>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LessonsCubit>(),
        child: _LessonDetailsDialog(lesson: lesson),
      ),
    );

    if (action == _LessonDetailsAction.edit && context.mounted) {
      await _openEditDialog(context, lesson);
    }
  }

  void _handleCalendarTap(BuildContext context, CalendarTapDetails details) {
    final appointment = details.appointments?.firstOrNull;
    if (appointment is Appointment) {
      final lesson = context.read<LessonsCubit>().state.lessons.firstWhere(
        (lesson) => lesson.id == appointment.id,
      );
      _openLessonDetails(context, lesson);
      return;
    }

    final date = details.date;
    if (date != null) {
      _openCreateDialog(context, _roundToHour(date));
    }
  }

  DateTime _roundToHour(DateTime value) {
    return DateTime(value.year, value.month, value.day, value.hour);
  }

  void _changeCalendarView(CalendarView view) {
    setState(() {
      _calendarView = view;
      _calendarController.view = view;
    });
  }

  Future<void> _handleViewChanged(
    BuildContext context,
    ViewChangedDetails details,
  ) async {
    if (details.visibleDates.isEmpty) {
      return;
    }

    final from = DateTime(
      details.visibleDates.first.year,
      details.visibleDates.first.month,
      details.visibleDates.first.day,
    );
    final last = details.visibleDates.last;
    final to = DateTime(
      last.year,
      last.month,
      last.day,
    ).add(const Duration(days: 1));
    final cubit = context.read<LessonsCubit>();
    if (cubit.state.filters.from == from && cubit.state.filters.to == to) {
      return;
    }

    await cubit.changeRange(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LessonsCubit, LessonsState>(
      listenWhen: (previous, current) =>
          previous.errorEventId != current.errorEventId &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorStatusCode == 401) {
          showSessionExpired(context);
        } else {
          showAppSnackBar(context, state.errorMessage!);
        }
        if (state.errorStatusCode == 401) {
          context.read<AuthCubit>().logout();
        }
      },
      child: BlocBuilder<LessonsCubit, LessonsState>(
        builder: (context, state) {
          final dataSource = _LessonsDataSource(
            context: context,
            lessons: state.lessons,
            instructors: state.instructors,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      'Voznje',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SegmentedButton<CalendarView>(
                    segments: _calendarViewOptions
                        .map(
                          (option) => ButtonSegment<CalendarView>(
                            value: option.view,
                            label: Text(option.label),
                          ),
                        )
                        .toList(),
                    selected: {_calendarView},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        _changeCalendarView(selection.first),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      initialValue: state.filters.instructorId,
                      decoration: const InputDecoration(
                        labelText: 'Instruktor',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Svi instruktori'),
                        ),
                        if (state.filters.instructorId != null &&
                            !state.instructors.any(
                              (i) => i.id == state.filters.instructorId,
                            ))
                          DropdownMenuItem(
                            value: state.filters.instructorId,
                            child: const Text('Odabrani instruktor'),
                          ),
                        ...state.instructors.map(
                          (instructor) => DropdownMenuItem(
                            value: instructor.id,
                            child: Text(instructor.fullName),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          context.read<LessonsCubit>().filterInstructor(value),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      initialValue: state.filters.status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Svi statusi'),
                        ),
                        ...lessonStatuses.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(lessonStatusLabel(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          context.read<LessonsCubit>().filterStatus(value),
                    ),
                  ),
                  if (state.filters.candidateId != null)
                    InputChip(
                      label: Text(
                        'Kandidat: ${state.candidates.where((c) => c.id == state.filters.candidateId).firstOrNull?.fullName ?? "odabrani kandidat"}',
                      ),
                      onDeleted: context
                          .read<LessonsCubit>()
                          .clearCandidateFilter,
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openCreateDialog(
                      context,
                      DateTime.now().add(const Duration(hours: 1)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Novi termin'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.status == LessonsStatus.failure)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppInlineError(
                    message:
                        state.errorMessage ?? 'Termine nije moguce ucitati.',
                    onRetry: () => context.read<LessonsCubit>().load(),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    SfCalendar(
                      controller: _calendarController,
                      view: _calendarView,
                      dataSource: dataSource,
                      firstDayOfWeek: 1,
                      todayHighlightColor: Theme.of(
                        context,
                      ).colorScheme.primary,
                      onTap: (details) => _handleCalendarTap(context, details),
                      onViewChanged: (details) =>
                          _handleViewChanged(context, details),
                      appointmentBuilder: (context, details) {
                        final appointment = details.appointments.firstOrNull;
                        if (appointment is! Appointment) {
                          return const SizedBox.shrink();
                        }

                        final lesson = state.lessons.firstWhere(
                          (lesson) => lesson.id == appointment.id,
                        );
                        return _LessonAppointmentTile(lesson: lesson);
                      },
                      timeSlotViewSettings: const TimeSlotViewSettings(
                        startHour: 7,
                        endHour: 21,
                        timeInterval: Duration(minutes: 60),
                        timeIntervalHeight: 84,
                        timeIntervalWidth: 110,
                        timelineAppointmentHeight: 64,
                        timeRulerSize: 64,
                        timeFormat: 'HH:mm',
                      ),
                      resourceViewSettings: const ResourceViewSettings(
                        visibleResourceCount: 5,
                        showAvatar: false,
                      ),
                    ),
                    if (state.status == LessonsStatus.loading)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AppLoadingState(isRefreshing: true),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _LessonDetailsDialog extends StatelessWidget {
  const _LessonDetailsDialog({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonsCubit, LessonsState>(
      builder: (context, state) {
        return AlertDialog(
          title: Text(lesson.candidateName),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Instruktor', value: lesson.instructorName),
                _DetailRow(
                  label: 'Status',
                  value: lessonStatusLabel(lesson.status),
                ),
                _DetailRow(label: 'Kategorija', value: lesson.categoryCode),
                _DetailRow(
                  label: 'Termin',
                  value:
                      '${formatDate(lesson.startAt)} ${formatTime(lesson.startAt)}-${formatTime(lesson.endAt)}',
                ),
                if (lesson.notes != null && lesson.notes!.isNotEmpty)
                  _DetailRow(label: 'Napomena', value: lesson.notes!),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Zatvori'),
            ),
            if (lesson.status != 'COMPLETED' && lesson.status != 'NO_SHOW')
              TextButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () =>
                          Navigator.of(context).pop(_LessonDetailsAction.edit),
                icon: const Icon(Icons.edit),
                label: const Text('Uredi'),
              ),
            if (lesson.status == 'REQUESTED')
              FilledButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final confirmed = await context
                            .read<LessonsCubit>()
                            .confirm(lesson.id);
                        if (confirmed && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                icon: const Icon(Icons.check),
                label: const Text('Potvrdi'),
              ),
            if (lesson.status == 'REQUESTED' || lesson.status == 'CONFIRMED')
              FilledButton.tonalIcon(
                onPressed: state.isSubmitting
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
                        final cancelled = await context
                            .read<LessonsCubit>()
                            .cancel(lesson.id);
                        if (cancelled && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                icon: const Icon(Icons.close),
                label: const Text('Otkazi'),
              ),
          ],
        );
      },
    );
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

final class _LessonAppointmentTile extends StatelessWidget {
  const _LessonAppointmentTile({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, lesson.status);
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final isCompact = height < 38;
        final showInstructor = height >= 44;
        final showMeta = height >= 58;
        final borderRadius = BorderRadius.circular(6);

        if (isCompact) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: color, borderRadius: borderRadius),
            alignment: Alignment.centerLeft,
            child: Text(
              lesson.candidateName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: height < 24 ? 10 : 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 6,
            vertical: isCompact ? 1 : 4,
          ),
          decoration: BoxDecoration(color: color, borderRadius: borderRadius),
          child: ClipRect(
            child: DefaultTextStyle(
              style: TextStyle(
                color: foreground,
                fontSize: isCompact ? 11 : 12,
                height: 1.05,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lesson.candidateName,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showInstructor)
                    Text(
                      lesson.instructorName,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.9),
                        fontSize: 10,
                      ),
                    ),
                  if (showMeta)
                    Text(
                      '${lessonStatusLabel(lesson.status)} · ${lesson.categoryCode}',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.9),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LessonsDataSource extends CalendarDataSource {
  _LessonsDataSource({
    required BuildContext context,
    required List<Lesson> lessons,
    required List<Instructor> instructors,
  }) {
    appointments = lessons
        .map(
          (lesson) => Appointment(
            id: lesson.id,
            startTime: lesson.startAt,
            endTime: lesson.endAt,
            subject:
                '${lesson.candidateName} · ${lessonStatusLabel(lesson.status)}',
            notes: lesson.notes,
            color: statusColor(context, lesson.status),
            resourceIds: [lesson.instructorId],
          ),
        )
        .toList();
    resources = instructors
        .map(
          (instructor) => CalendarResource(
            id: instructor.id,
            displayName: instructor.fullName,
            color: Theme.of(context).colorScheme.primary,
          ),
        )
        .toList();
  }
}
