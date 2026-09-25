import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../cubit/portal_cubit.dart';
import '../cubit/portal_state.dart';
import '../utils/lesson_formatters.dart';

final class RequestLessonPage extends StatefulWidget {
  const RequestLessonPage({super.key});
  @override
  State<RequestLessonPage> createState() => _RequestLessonPageState();
}

class _RequestLessonPageState extends State<RequestLessonPage> {
  final _notes = TextEditingController();
  late DateTime _start = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  ).add(const Duration(hours: 9));
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _date() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateUtils.dateOnly(now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (mounted && value != null) {
      setState(
        () => _start = DateTime(
          value.year,
          value.month,
          value.day,
          _start.hour,
          _start.minute,
        ),
      );
    }
  }

  Future<void> _time() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (mounted && value != null) {
      setState(
        () => _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          value.hour,
          value.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<PortalCubit, PortalState>(
    listenWhen: (a, b) => a.savedId != b.savedId,
    listener: (context, state) => context.go('/lessons/request-sent'),
    builder: (context, state) => PopScope(
      canPop: !state.saving,
      child: AppPage(
        maxWidth: 720,
        child: ListView(
          children: [
            Text(
              'Zatraži vožnju',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Odaberi vrijeme koje ti odgovara.'),
            const SizedBox(height: 32),
            if (state.loading) const AppLoadingState(isRefreshing: true),
            if (state.loadFailure != null)
              AppInlineError(
                message: state.loadFailure!.message,
                onRetry: () => context.read<PortalCubit>().load(),
              ),
            if (state.data != null) ...[
              TextFormField(
                key: ValueKey('date:$_start'),
                initialValue: lessonDate(context, _start),
                readOnly: true,
                enabled: !state.saving,
                maxLines: null,
                onTap: _date,
                decoration: const InputDecoration(
                  labelText: 'Željeni datum',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('time:$_start'),
                initialValue: lessonTime(context, _start),
                readOnly: true,
                enabled: !state.saving,
                onTap: _time,
                decoration: const InputDecoration(
                  labelText: 'Vrijeme početka',
                  suffixIcon: Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: 16),
              const InputDecorator(
                decoration: InputDecoration(labelText: 'Trajanje'),
                child: Text('60 minuta'),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('request-note'),
                controller: _notes,
                enabled: !state.saving,
                maxLength: 2000,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Napomena (neobavezno)',
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: AppStatusBadge(
                  label: 'Čeka potvrdu',
                  tone: AppTone.warning,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ovo je zahtjev termina. Vožnja je dogovorena tek nakon potvrde. Zahtjev ne dodaje odrađene sate.',
              ),
              const SizedBox(height: 24),
              if (state.data?.canRequestLesson != true)
                const Text(
                  'Za slanje zahtjeva potreban je dodijeljeni aktivni instruktor.',
                ),
              FilledButton(
                onPressed: state.saving || state.data?.canRequestLesson != true
                    ? null
                    : () => context.read<PortalCubit>().requestLesson(
                        _start,
                        _notes.text.trim(),
                      ),
                child: Text(state.saving ? 'Slanje…' : 'Pošalji zahtjev'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: state.saving ? null : () => context.go('/lessons'),
                child: const Text('Odustani'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
