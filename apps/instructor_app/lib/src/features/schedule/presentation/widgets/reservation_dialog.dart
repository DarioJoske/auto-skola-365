import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reserve_lesson.dart';
import '../cubit/reservation_cubit.dart';

final class ReservationDialog extends StatefulWidget {
  const ReservationDialog({
    required this.initialDate,
    this.candidateId,
    super.key,
  });
  final DateTime initialDate;
  final String? candidateId;
  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String? _candidateId;
  late DateTime _startAt;
  @override
  void initState() {
    super.initState();
    _candidateId = widget.candidateId;
    final now = DateTime.now();
    final date = widget.initialDate.isBefore(now) ? now : widget.initialDate;
    _startAt = DateTime(date.year, date.month, date.day, date.hour + 1);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(
      () => _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        _startAt.hour,
        _startAt.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (time == null || !mounted) return;
    setState(
      () => _startAt = DateTime(
        _startAt.year,
        _startAt.month,
        _startAt.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!_startAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termin mora biti u budućnosti.')),
      );
      return;
    }
    context.read<ReservationCubit>().reserve(
      ReserveLesson(
        candidateId: _candidateId!,
        startAt: _startAt,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ReservationCubit, ReservationState>(
    listenWhen: (previous, current) => previous.eventId != current.eventId,
    listener: (context, state) {
      if (state.saved) {
        Navigator.of(context).pop(true);
        return;
      }
      final failure = state.saveFailure ?? state.loadFailure;
      if (failure?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesija je istekla. Prijavite se ponovno.'),
          ),
        );
        Navigator.of(context).pop(false);
        return;
      }
      if (state.saveFailure != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.saveFailure!.message)));
      }
    },
    builder: (context, state) => PopScope(
      canPop: !state.saving,
      child: AlertDialog(
        title: const Text('Rezerviraj termin'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.loadFailure != null) ...[
                    Text(state.loadFailure!.message),
                    TextButton(
                      onPressed: () => context.read<ReservationCubit>().load(),
                      child: const Text('Pokušaj ponovno'),
                    ),
                  ] else if (!state.loading && state.candidates.isEmpty)
                    const Text('Nemate dodijeljenih kandidata za rezervaciju.'),
                  AppDropdownFormField<String>(
                    key: ValueKey(state.candidates.map((c) => c.id).join(',')),
                    initialValue:
                        state.candidates.any((c) => c.id == _candidateId)
                        ? _candidateId
                        : null,

                    decoration: const InputDecoration(labelText: 'Kandidat'),
                    items: state.candidates
                        .map(
                          (c) =>
                              AppDropdownOption(value: c.id, label: c.fullName),
                        )
                        .toList(),
                    onChanged: state.saving || state.loading
                        ? null
                        : (value) => setState(() => _candidateId = value),
                    validator: (value) =>
                        value == null ? 'Odaberite kandidata.' : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: state.saving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${_startAt.day}.${_startAt.month}.${_startAt.year}.',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.saving ? null : _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      '${_startAt.hour.toString().padLeft(2, '0')}:${_startAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const Text('Trajanje: 60 min. Termin će biti potvrđen.'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    enabled: !state.saving,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Napomena (neobavezno)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.saving
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed:
                state.loading ||
                    state.saving ||
                    state.candidates.isEmpty ||
                    state.loadFailure != null
                ? null
                : _submit,
            child: Text(state.saving ? 'Spremanje…' : 'Rezerviraj'),
          ),
        ],
      ),
    ),
  );
}
