import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/portal_cubit.dart';
import '../utils/lesson_formatters.dart';
import '../cubit/portal_state.dart';

Future<void> showLessonRequest(BuildContext context) async {
  final cubit = context.read<PortalCubit>();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const RequestLessonDialog()),
  );
}

final class RequestLessonDialog extends StatefulWidget {
  const RequestLessonDialog({super.key});
  @override
  State<RequestLessonDialog> createState() => _RequestLessonDialogState();
}

class _RequestLessonDialogState extends State<RequestLessonDialog> {
  final _notes = TextEditingController();
  late DateTime _date;
  @override
  void initState() {
    super.initState();
    final day = DateTime.now().add(const Duration(days: 1));
    _date = DateTime(day.year, day.month, day.day, 9);
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
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (!mounted || date == null) return;
    setState(
      () => _date = DateTime(
        date.year,
        date.month,
        date.day,
        _date.hour,
        _date.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted || time == null) return;
    setState(
      () => _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<PortalCubit, PortalState>(
    listenWhen: (previous, current) =>
        previous.savedId != current.savedId ||
        ((current.actionFailure ?? current.loadFailure)?.statusCode == 401 &&
            previous.errorId != current.errorId),
    listener: (context, state) {
      if ((state.actionFailure ?? state.loadFailure)?.statusCode == 401) {
        Navigator.of(context).pop();
        return;
      }
      if (state.savedId != 0 && state.actionFailure == null && !state.saving) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zahtjev je poslan. Čeka potvrdu instruktora.'),
          ),
        );
      } else if ((state.actionFailure ?? state.loadFailure)?.statusCode ==
          401) {
        Navigator.of(context).pop();
      }
    },
    builder: (context, state) => PopScope(
      canPop: !state.saving,
      child: AlertDialog(
        title: const Text('Zatraži termin'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Instruktor: ${state.data?.instructorName ?? 'Nije dodijeljen'}',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: state.saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(lessonDate(context, _date)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.saving ? null : _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(lessonTime(context, _date)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Termin traje 60 minuta i vrijedi nakon potvrde instruktora.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  enabled: !state.saving,
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Napomena (neobavezno)',
                  ),
                ),
                if (state.actionFailure != null)
                  Text(
                    state.actionFailure!.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: state.saving || state.data?.canRequestLesson != true
                ? null
                : () => context.read<PortalCubit>().requestLesson(
                    _date,
                    _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                  ),
            child: Text(state.saving ? 'Slanje…' : 'Pošalji zahtjev'),
          ),
        ],
      ),
    ),
  );
}
