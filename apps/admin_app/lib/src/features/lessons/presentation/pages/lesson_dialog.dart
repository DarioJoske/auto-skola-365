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
            width: 520,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
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
                                i.active || i.id == widget.lesson?.instructorId,
                          )
                          .map(
                            (instructor) => DropdownMenuItem(
                              value: instructor.id,
                              child: Text(instructor.fullName),
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
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      key: ValueKey('$_instructorId:$selectedCandidate'),
                      initialValue: selectedCandidate,
                      decoration: const InputDecoration(labelText: 'Kandidat'),
                      items: candidates
                          .map(
                            (candidate) => DropdownMenuItem(
                              value: candidate.id,
                              child: Text(candidate.fullName),
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
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: lessonStatuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(lessonStatusLabel(status)),
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
                            label: Text(formatDate(_startAt)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(formatTime(_startAt)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Trajanje: 60 min · kraj ${formatTime(_startAt.add(const Duration(minutes: 60)))}',
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
}
