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
import 'lesson_week_board.dart';

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
  const LessonsView({this.openCreateOnLoad = false, super.key});
  final bool openCreateOnLoad;

  @override
  State<LessonsView> createState() => _LessonsViewState();
}

class _LessonsViewState extends State<LessonsView> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _calendarView = CalendarView.week;
  bool _showWeekend = false;

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = context
        .read<LessonsCubit>()
        .state
        .filters
        .from;
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openCreateDialog(
            context,
            DateTime.now().add(const Duration(hours: 1)),
          );
        }
      });
    }
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

    await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LessonsCubit>(),
        child: LessonDialog(initialStartAt: startAt),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, Lesson lesson) async {
    final cubit = context.read<LessonsCubit>();
    await cubit.load();
    if (!context.mounted || cubit.state.status == LessonsStatus.failure) return;
    await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LessonsCubit>(),
        child: LessonDialog(lesson: lesson),
      ),
    );
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
    if (view == CalendarView.week) {
      _showWeek(context.read<LessonsCubit>().state.filters.from);
    }
  }

  void _showWeek(DateTime date) {
    final start = DateTime(date.year, date.month, date.day - date.weekday + 1);
    _calendarController.displayDate = start;
    context.read<LessonsCubit>().changeRange(
      start,
      DateTime(start.year, start.month, start.day + 7),
    );
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _calendarView == CalendarView.week) return;
      cubit.changeRange(from, to);
    });
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
            instructors: state.instructors
                .where(
                  (instructor) =>
                      state.filters.instructorId == null ||
                      instructor.id == state.filters.instructorId,
                )
                .toList(),
          );

          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScheduleHeader(
                    state: state,
                    view: _calendarView,
                    onCreate: () => _openCreateDialog(
                      context,
                      DateTime.now().add(const Duration(hours: 1)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ScheduleToolbar(
                    state: state,
                    view: _calendarView,
                    onShowWeek: _showWeek,
                    onViewChanged: _changeCalendarView,
                    showWeekend: _showWeekend,
                    onWeekendChanged: (value) =>
                        setState(() => _showWeekend = value),
                  ),
                  const SizedBox(height: 24),
                  if (state.status == LessonsStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppInlineError(
                        message:
                            state.errorMessage ??
                            'Termine nije moguće učitati.',
                        onRetry: () => context.read<LessonsCubit>().load(),
                      ),
                    ),
                  if (_calendarView == CalendarView.week) ...[
                    if (state.status == LessonsStatus.loading)
                      const AppLoadingState(isRefreshing: true),
                    LessonWeekBoard(
                      from: state.filters.from,
                      lessons: state.lessons,
                      onOpen: (lesson) => _openLessonDetails(context, lesson),
                      showWeekend:
                          _showWeekend ||
                          state.lessons.any(
                            (lesson) =>
                                lesson.startAt.weekday >= DateTime.saturday ||
                                lesson.endAt
                                        .subtract(
                                          const Duration(microseconds: 1),
                                        )
                                        .weekday >=
                                    DateTime.saturday,
                          ),
                    ),
                  ] else
                    SizedBox(
                      height: constraints.maxHeight.clamp(500.0, 900.0),
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
                            onTap: (details) =>
                                _handleCalendarTap(context, details),
                            onViewChanged: (details) =>
                                _handleViewChanged(context, details),
                            appointmentBuilder: (context, details) {
                              final appointment =
                                  details.appointments.firstOrNull;
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
              ),
            ),
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
    return BlocConsumer<LessonsCubit, LessonsState>(
      listenWhen: (previous, current) =>
          previous.savedEventId != current.savedEventId,
      listener: (context, state) => Navigator.of(context).pop(),
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
                if (lesson.proposedStartAt case final proposed?)
                  _DetailRow(
                    label: 'Čeka odgovor kandidata',
                    value:
                        '${formatDate(proposed)} ${formatTime(proposed)} · 60 minuta',
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
            if (lesson.status != 'COMPLETED' &&
                lesson.status != 'NO_SHOW' &&
                lesson.proposedStartAt == null)
              TextButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () =>
                          Navigator.of(context).pop(_LessonDetailsAction.edit),
                icon: const Icon(Icons.edit),
                label: const Text('Uredi'),
              ),
            if (lesson.status == 'REQUESTED' && lesson.proposedStartAt == null)
              FilledButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        await context.read<LessonsCubit>().confirm(lesson.id);
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
                        await context.read<LessonsCubit>().cancel(lesson.id);
                      },
                icon: const Icon(Icons.close),
                label: const Text('Otkaži'),
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

final class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.state,
    required this.view,
    required this.onCreate,
  });
  final LessonsState state;
  final CalendarView view;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final from = state.filters.from;
    final to = state.filters.to.subtract(const Duration(days: 1));
    const months = [
      'siječnja',
      'veljače',
      'ožujka',
      'travnja',
      'svibnja',
      'lipnja',
      'srpnja',
      'kolovoza',
      'rujna',
      'listopada',
      'studenoga',
      'prosinca',
    ];
    final start = from.month == to.month && from.year == to.year
        ? '${from.day}.'
        : '${from.day}. ${months[from.month - 1]} ${from.year}.';
    final instructor =
        state.instructors
            .where((i) => i.id == state.filters.instructorId)
            .firstOrNull
            ?.fullName ??
        (state.filters.instructorId == null
            ? 'svi instruktori'
            : 'odabrani instruktor');
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          view == CalendarView.week ? 'Tjedni raspored' : 'Raspored',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '$start – ${to.day}. ${months[to.month - 1]} ${to.year}. · $instructor',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final create = SizedBox(
      width: 180,
      child: FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Novi termin'),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700 ||
            MediaQuery.textScalerOf(context).scale(14) > 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 16), create],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 24),
            create,
          ],
        );
      },
    );
  }
}

final class _ScheduleToolbar extends StatelessWidget {
  const _ScheduleToolbar({
    required this.state,
    required this.view,
    required this.onShowWeek,
    required this.onViewChanged,
    required this.showWeekend,
    required this.onWeekendChanged,
  });
  final LessonsState state;
  final CalendarView view;
  final ValueChanged<DateTime> onShowWeek;
  final ValueChanged<CalendarView> onViewChanged;
  final bool showWeekend;
  final ValueChanged<bool> onWeekendChanged;

  @override
  Widget build(BuildContext context) {
    final instructor =
        state.instructors
            .where((i) => i.id == state.filters.instructorId)
            .firstOrNull
            ?.fullName ??
        (state.filters.instructorId == null
            ? 'Svi instruktori'
            : 'Odabrani instruktor');
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (view == CalendarView.week)
          SizedBox(
            width: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Prethodni tjedan',
                    onPressed: () => onShowWeek(
                      DateTime(
                        state.filters.from.year,
                        state.filters.from.month,
                        state.filters.from.day - 7,
                      ),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => onShowWeek(DateTime.now()),
                      child: const Text('Danas'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sljedeći tjedan',
                    onPressed: () => onShowWeek(
                      DateTime(
                        state.filters.from.year,
                        state.filters.from.month,
                        state.filters.from.day + 7,
                      ),
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: 220,
          child: MenuAnchor(
            style: const MenuStyle(
              maximumSize: WidgetStatePropertyAll(Size(280, 320)),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () =>
                    context.read<LessonsCubit>().filterInstructor(null),
                child: const Text('Svi instruktori'),
              ),
              for (final instructor in state.instructors)
                MenuItemButton(
                  onPressed: () => context
                      .read<LessonsCubit>()
                      .filterInstructor(instructor.id),
                  trailingIcon: state.filters.instructorId == instructor.id
                      ? const Icon(Icons.check, size: 20)
                      : null,
                  child: Text(instructor.fullName),
                ),
            ],
            builder: (context, controller, child) => Tooltip(
              message: 'Filtriraj instruktora',
              child: FilledButton.tonal(
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: Text(instructor)),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final option in _calendarViewOptions.where(
          (option) =>
              option.view == CalendarView.week ||
              option.view == CalendarView.month,
        ))
          SizedBox(
            width: 120,
            child: view == option.view
                ? FilledButton(
                    onPressed: () => onViewChanged(option.view),
                    child: Text(option.label),
                  )
                : TextButton(
                    onPressed: () => onViewChanged(option.view),
                    child: Text(option.label),
                  ),
          ),
        MenuAnchor(
          style: const MenuStyle(
            maximumSize: WidgetStatePropertyAll(Size(280, 320)),
          ),
          builder: (context, controller, child) => IconButton(
            tooltip: 'Dodatni prikazi i filtri',
            icon: const Icon(Icons.more_horiz),
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            for (final option in _calendarViewOptions.where(
              (option) =>
                  option.view != CalendarView.week &&
                  option.view != CalendarView.month,
            ))
              MenuItemButton(
                onPressed: () => onViewChanged(option.view),
                trailingIcon: view == option.view
                    ? const Icon(Icons.check, size: 20)
                    : null,
                child: Text(option.label),
              ),
            MenuItemButton(
              onPressed: () => onWeekendChanged(!showWeekend),
              trailingIcon: showWeekend
                  ? const Icon(Icons.check, size: 20)
                  : null,
              child: const Text('Prikaži vikend'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: () => context.read<LessonsCubit>().filterStatus(null),
              trailingIcon: state.filters.status == null
                  ? const Icon(Icons.check, size: 20)
                  : null,
              child: const Text('Svi statusi'),
            ),
            for (final status in lessonFilterStatuses)
              MenuItemButton(
                onPressed: () =>
                    context.read<LessonsCubit>().filterStatus(status),
                trailingIcon: state.filters.status == status
                    ? const Icon(Icons.check, size: 20)
                    : null,
                child: Text(lessonStatusLabel(status)),
              ),
          ],
        ),
        if (view != CalendarView.week && view != CalendarView.month)
          Chip(
            label: Text(
              _calendarViewOptions
                  .firstWhere((option) => option.view == view)
                  .label,
            ),
          ),
        if (state.filters.status != null)
          InputChip(
            label: Text(lessonStatusLabel(state.filters.status!)),
            onDeleted: () => context.read<LessonsCubit>().filterStatus(null),
          ),
        if (state.filters.candidateId != null)
          InputChip(
            label: Text(
              'Kandidat: ${state.candidates.where((c) => c.id == state.filters.candidateId).firstOrNull?.fullName ?? "odabrani kandidat"}',
            ),
            onDeleted: context.read<LessonsCubit>().clearCandidateFilter,
          ),
      ],
    );
  }
}
