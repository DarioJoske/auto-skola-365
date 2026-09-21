import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/save_lesson.dart';
import '../cubit/lessons_cubit.dart';
import '../cubit/lessons_state.dart';

import 'lesson_presentation.dart';

final class LessonDialog extends StatefulWidget {
  const LessonDialog({this.lesson, this.initialStartAt, super.key});

  final Lesson? lesson;
  final DateTime? initialStartAt;

  @override
  State<LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<LessonDialog> {
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
    _instructorId =
        lesson?.instructorId ??
        context
            .read<LessonsCubit>()
            .state
            .instructors
            .where(
              (instructor) =>
                  instructor.active &&
                  instructor.id ==
                      context.read<LessonsCubit>().state.filters.instructorId,
            )
            .firstOrNull
            ?.id;
    _notesController.text = lesson?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final earliest = now.subtract(const Duration(days: 30));
    final latest = now.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: _startAt.isBefore(earliest) ? _startAt : earliest,
      lastDate: _startAt.isAfter(latest) ? _startAt : latest,
    );
    if (picked == null || !mounted) {
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
    if (picked == null || !mounted) {
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
    if (widget.lesson == null) {
      await cubit.create(lesson);
    } else {
      await cubit.update(widget.lesson!.id, lesson);
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
    return PopScope(
      canPop: !context.select((LessonsCubit cubit) => cubit.state.isSubmitting),
      child: BlocConsumer<LessonsCubit, LessonsState>(
        listenWhen: (previous, current) =>
            previous.savedEventId != current.savedEventId,
        listener: (context, state) => Navigator.of(context).pop(true),
        builder: (context, state) {
          final candidates = state.candidates
              .where(
                (candidate) =>
                    _instructorId != null &&
                    candidate.assignedInstructorId == _instructorId,
              )
              .toList();
          final selectedCandidate =
              candidates.any((candidate) => candidate.id == _candidateId)
              ? _candidateId
              : null;

          return AlertDialog(
            title: Text(_isEditing ? 'Uredi termin' : 'Novi termin'),
            content: SizedBox(
              width: 640,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Dogovori vožnju',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      AppDropdownFormField<String>(
                        initialValue:
                            state.instructors.any((i) => i.id == _instructorId)
                            ? _instructorId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Instruktor',
                        ),
                        items: state.instructors
                            .where(
                              (i) =>
                                  i.active ||
                                  i.id == widget.lesson?.instructorId,
                            )
                            .map(
                              (instructor) => AppDropdownOption(
                                value: instructor.id,
                                label: instructor.fullName,
                              ),
                            )
                            .toList(),
                        validator: _required,
                        onChanged: state.isSubmitting
                            ? null
                            : (value) => setState(() {
                                _instructorId = value;
                                _candidateId = null;
                              }),
                      ),
                      const SizedBox(height: 12),
                      AppDropdownFormField<String>(
                        key: ValueKey('$_instructorId:$selectedCandidate'),
                        initialValue: selectedCandidate,
                        decoration: const InputDecoration(
                          labelText: 'Kandidat',
                        ),
                        items: candidates
                            .map(
                              (candidate) => AppDropdownOption(
                                value: candidate.id,
                                label: candidate.fullName,
                              ),
                            )
                            .toList(),
                        validator: _required,
                        onChanged: state.isSubmitting || candidates.isEmpty
                            ? null
                            : (value) => setState(() => _candidateId = value),
                      ),
                      if (_instructorId == null)
                        const Text('Prvo odaberite instruktora.')
                      else if (candidates.isEmpty)
                        const Text(
                          'Odabrani instruktor nema dodijeljenih kandidata.',
                        ),
                      const SizedBox(height: 12),
                      AppDropdownFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: lessonStatuses
                            .map(
                              (status) => AppDropdownOption(
                                value: status,
                                label: lessonStatusLabel(status),
                              ),
                            )
                            .toList(),
                        onChanged: state.isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _status = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      _LessonDateTimeFields(
                        startAt: _startAt,
                        onPickDate: state.isSubmitting ? null : _pickDate,
                        onPickTime: state.isSubmitting ? null : _pickTime,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Trajanje: 60 min · kraj ${formatTime(_startAt.add(const Duration(minutes: 60)))}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        enabled: !state.isSubmitting,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Interna napomena',
                          helperText:
                              'Neobavezno; vidljivo samo ovlaštenom osoblju škole.',
                          helperMaxLines: 3,
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dodjela kandidata i preklapanja provjeravaju se pri spremanju. Termin traje 60 minuta.',
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        AppNotice(
                          title: 'Termin nije spremljen',
                          message: state.errorMessage!,
                          tone: AppTone.error,
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
      ),
    );
  }
}

final class _LessonDateTimeFields extends StatelessWidget {
  const _LessonDateTimeFields({
    required this.startAt,
    required this.onPickDate,
    required this.onPickTime,
  });
  final DateTime startAt;
  final VoidCallback? onPickDate, onPickTime;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final date = OutlinedButton.icon(
        onPressed: onPickDate,
        icon: const Icon(Icons.calendar_month),
        label: Text(formatDate(startAt)),
      );
      final time = OutlinedButton.icon(
        onPressed: onPickTime,
        icon: const Icon(Icons.schedule),
        label: Text(formatTime(startAt)),
      );
      if (constraints.maxWidth < 400 ||
          MediaQuery.textScalerOf(context).scale(14) > 21) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [date, const SizedBox(height: 12), time],
        );
      }
      return Row(
        children: [
          Expanded(child: date),
          const SizedBox(width: 12),
          Expanded(child: time),
        ],
      );
    },
  );
}
