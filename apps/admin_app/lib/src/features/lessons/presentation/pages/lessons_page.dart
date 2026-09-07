import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../candidates/domain/entities/candidate.dart';
import '../../../candidates/domain/usecases/list_candidates.dart';
import '../../../instructors/domain/entities/instructor.dart';
import '../../../instructors/domain/usecases/list_instructors.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/save_lesson.dart';
import '../../domain/usecases/cancel_lesson.dart';
import '../../domain/usecases/confirm_lesson.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/list_lessons.dart';
import '../../domain/usecases/update_lesson.dart';
import '../cubit/lessons_cubit.dart';
import '../cubit/lessons_state.dart';

const _lessonStatuses = ['REQUESTED', 'CONFIRMED', 'CANCELLED'];

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

class LessonsPage extends StatelessWidget {
  const LessonsPage({
    required this.listLessons,
    required this.createLesson,
    required this.updateLesson,
    required this.confirmLesson,
    required this.cancelLesson,
    required this.listCandidates,
    required this.listInstructors,
    super.key,
  });

  final ListLessons listLessons;
  final CreateLessonUseCase createLesson;
  final UpdateLessonUseCase updateLesson;
  final ConfirmLessonUseCase confirmLesson;
  final CancelLessonUseCase cancelLesson;
  final ListCandidates listCandidates;
  final ListInstructors listInstructors;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final membership = authState.user!.primaryMembership!;

    return BlocProvider(
      create: (_) => LessonsCubit(
        listLessons: listLessons,
        createLesson: createLesson,
        updateLesson: updateLesson,
        confirmLesson: confirmLesson,
        cancelLesson: cancelLesson,
        listCandidates: listCandidates,
        listInstructors: listInstructors,
        schoolId: membership.schoolId,
        accessToken: authState.accessToken!,
      )..load(),
      child: const LessonsView(),
    );
  }
}

class LessonsView extends StatefulWidget {
  const LessonsView({super.key});

  @override
  State<LessonsView> createState() => _LessonsViewState();
}

class _LessonsViewState extends State<LessonsView> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _calendarView = CalendarView.timelineWeek;

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog(BuildContext context, DateTime startAt) async {
    final state = context.read<LessonsCubit>().state;
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
        child: _LessonDialog(initialStartAt: startAt),
      ),
    );

    if (created == true && context.mounted) {
      await context.read<LessonsCubit>().load();
    }
  }

  Future<void> _openEditDialog(BuildContext context, Lesson lesson) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LessonsCubit>(),
        child: _LessonDialog(lesson: lesson),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
                        ..._lessonStatuses.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          context.read<LessonsCubit>().filterStatus(value),
                    ),
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
                  child: _InlineError(
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
      ),
    );
  }
}

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({this.lesson, this.initialStartAt});

  final Lesson? lesson;
  final DateTime? initialStartAt;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late DateTime _startAt;
  late String _status;
  String? _candidateId;
  String? _instructorId;

  bool get _isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();

    final lesson = widget.lesson;
    _startAt = lesson?.startAt ?? widget.initialStartAt ?? DateTime.now();
    _status = lesson?.status ?? 'REQUESTED';
    _candidateId = lesson?.candidateId;
    _instructorId = lesson?.instructorId;
    _notesController.text = lesson?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _startAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _startAt.hour,
        _startAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _startAt = DateTime(
        _startAt.year,
        _startAt.month,
        _startAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _candidateChanged(String? candidateId, LessonsState state) {
    final candidate = state.candidates
        .where((candidate) => candidate.id == candidateId)
        .firstOrNull;
    setState(() {
      _candidateId = candidateId;
      if (candidate?.assignedInstructorId != null) {
        _instructorId = candidate!.assignedInstructorId;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final lesson = SaveLesson(
      candidateId: _candidateId!,
      instructorId: _instructorId!,
      lessonType: 'DRIVING',
      status: _status,
      startAt: _startAt,
      endAt: _startAt.add(const Duration(minutes: 60)),
      notes: _emptyToNull(_notesController.text),
    );
    final cubit = context.read<LessonsCubit>();
    final saved = widget.lesson == null
        ? await cubit.create(lesson)
        : await cubit.update(widget.lesson!.id, lesson);

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Obavezno polje' : null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonsCubit, LessonsState>(
      builder: (context, state) {
        _candidateId ??= state.candidates.firstOrNull?.id;
        _instructorId ??=
            _selectedCandidate(state)?.assignedInstructorId ??
            state.instructors.firstOrNull?.id;

        return AlertDialog(
          title: Text(_isEditing ? 'Uredi termin' : 'Novi termin'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _candidateId,
                      decoration: const InputDecoration(labelText: 'Kandidat'),
                      items: state.candidates
                          .map(
                            (candidate) => DropdownMenuItem(
                              value: candidate.id,
                              child: Text(candidate.fullName),
                            ),
                          )
                          .toList(),
                      validator: _required,
                      onChanged: (value) => _candidateChanged(value, state),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _instructorId,
                      decoration: const InputDecoration(
                        labelText: 'Instruktor',
                      ),
                      items: state.instructors
                          .map(
                            (instructor) => DropdownMenuItem(
                              value: instructor.id,
                              child: Text(instructor.fullName),
                            ),
                          )
                          .toList(),
                      validator: _required,
                      onChanged: (value) => setState(() {
                        _instructorId = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _lessonStatuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(_formatDate(_startAt)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(_formatTime(_startAt)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Trajanje: 60 min · kraj ${_formatTime(_startAt.add(const Duration(minutes: 60)))}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Napomena'),
                      minLines: 2,
                      maxLines: 4,
                    ),
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: state.isSubmitting ? null : _submit,
              child: Text(state.isSubmitting ? 'Spremam...' : 'Spremi'),
            ),
          ],
        );
      },
    );
  }

  Candidate? _selectedCandidate(LessonsState state) {
    return state.candidates
        .where((candidate) => candidate.id == _candidateId)
        .firstOrNull;
  }
}

class _LessonDetailsDialog extends StatelessWidget {
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
                _DetailRow(label: 'Status', value: _statusLabel(lesson.status)),
                _DetailRow(label: 'Kategorija', value: lesson.categoryCode),
                _DetailRow(
                  label: 'Termin',
                  value:
                      '${_formatDate(lesson.startAt)} ${_formatTime(lesson.startAt)}-${_formatTime(lesson.endAt)}',
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
            TextButton.icon(
              onPressed: state.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(_LessonDetailsAction.edit),
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
            if (lesson.status != 'CANCELLED')
              FilledButton.tonalIcon(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
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

class _DetailRow extends StatelessWidget {
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
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

class _LessonAppointmentTile extends StatelessWidget {
  const _LessonAppointmentTile({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, lesson.status);
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
                      '${_statusLabel(lesson.status)} · ${lesson.categoryCode}',
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
            subject: '${lesson.candidateName} · ${_statusLabel(lesson.status)}',
            notes: lesson.notes,
            color: _statusColor(context, lesson.status),
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

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
