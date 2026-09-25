import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/availability.dart';
import '../cubit/availability_cubit.dart';

const _days = [
  'Ponedjeljak',
  'Utorak',
  'Srijeda',
  'Četvrtak',
  'Petak',
  'Subota',
  'Nedjelja',
];

final class AvailabilityView extends StatelessWidget {
  const AvailabilityView({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AvailabilityCubit, AvailabilityState>(
        listenWhen: (a, b) => a.saved != b.saved || a.failure != b.failure,
        listener: (context, state) {
          if (state.failure?.statusCode == 401) {
            showSessionExpired(context);
            context.read<AuthCubit>().logout();
          } else if (state.actionError) {
            showAppSnackBar(context, state.failure!.message);
          } else if (state.saved > 0 &&
              !state.loading &&
              !state.saving &&
              state.failure == null) {
            showAppSnackBar(context, 'Dostupnost je spremljena.');
          }
        },
        builder: (context, state) => AppPage(
          maxWidth: 720,
          child: ListView(
            children: [
              Text(
                'Moja dostupnost',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Postavi vrijeme za nove dogovore.'),
              const SizedBox(height: 24),
              if (state.loading)
                AppLoadingState(isRefreshing: state.data != null),
              if (state.failure != null && !state.actionError)
                AppInlineError(
                  message: state.failure!.message,
                  onRetry: () => context.read<AvailabilityCubit>().load(),
                ),
              if (state.data case final data?)
                _AvailabilityForm(
                  key: ValueKey(state.saved),
                  initial: data,
                  saving: state.saving,
                ),
            ],
          ),
        ),
      );
}

class _AvailabilityForm extends StatefulWidget {
  const _AvailabilityForm({
    required this.initial,
    required this.saving,
    super.key,
  });
  final Availability initial;
  final bool saving;
  @override
  State<_AvailabilityForm> createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends State<_AvailabilityForm> {
  late final List<WorkingPeriod> _rules = [...widget.initial.rules];
  late final List<UnavailablePeriod> _blocks = [...widget.initial.blocks];
  Future<void> _working() async {
    final rule = await showDialog<WorkingPeriod>(
      context: context,
      builder: (_) => const _WorkingDialog(),
    );
    if (mounted && rule != null) setState(() => _rules.add(rule));
  }

  Future<DateTime?> _instant(String title, DateTime initial) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      helpText: title,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (!mounted || day == null) return null;
    final time = await showTimePicker(
      context: context,
      helpText: title,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _block(String kind) async {
    final start = await _instant(
      'Početak',
      DateTime.now().add(const Duration(days: 1)),
    );
    if (!mounted || start == null) return;
    final end = await _instant(
      'Završetak',
      start.add(Duration(minutes: kind == 'BREAK' ? 30 : 60)),
    );
    if (!mounted || end == null) return;
    if (!end.isAfter(start)) {
      showAppSnackBar(context, 'Završetak mora biti nakon početka.');
      return;
    }
    setState(() => _blocks.add(UnavailablePeriod(start, end, kind)));
  }

  String _date(DateTime date) =>
      '${date.day}.${date.month}.${date.year}. ${TimeOfDay.fromDateTime(date).format(context)}';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Tjedno radno vrijeme · ${widget.initial.timeZone}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      if (_rules.isEmpty)
        const Text(
          'Bez tjednog ograničenja. Dodajte intervale za dane kada radite.',
        ),
      for (final r in _rules)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_days[r.day - 1]),
          subtitle: Text(
            '${r.start.substring(0, 5)} – ${r.end.substring(0, 5)}',
          ),
          trailing: IconButton(
            tooltip: 'Ukloni radno vrijeme',
            onPressed: widget.saving
                ? null
                : () => setState(() => _rules.remove(r)),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      OutlinedButton.icon(
        onPressed: widget.saving ? null : _working,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj radno vrijeme'),
      ),
      const SizedBox(height: 24),
      Text(
        'Pauze i odsutnosti',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const Text(
        'Datumi i vremena pauza prikazani su u lokalnom vremenu uređaja.',
      ),
      for (final b in _blocks)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(b.kind == 'BREAK' ? 'Pauza' : 'Odsutnost'),
          subtitle: Text('${_date(b.start)} – ${_date(b.end)}'),
          trailing: IconButton(
            tooltip: 'Ukloni nedostupnost',
            onPressed: widget.saving
                ? null
                : () => setState(() => _blocks.remove(b)),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: widget.saving ? null : () => _block('BREAK'),
        child: const Text('Dodaj pauzu'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: widget.saving ? null : () => _block('ABSENCE'),
        child: const Text('Dodaj odsutnost'),
      ),
      const SizedBox(height: 24),
      const Text(
        'Postojeći termini ostaju na rasporedu. Promjena koja bi im onemogućila održavanje bit će odbijena.',
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: widget.saving
            ? null
            : () => context.read<AvailabilityCubit>().save(
                Availability(
                  rules: _rules,
                  blocks: _blocks,
                  timeZone: widget.initial.timeZone,
                ),
              ),
        child: Text(widget.saving ? 'Spremanje…' : 'Spremi dostupnost'),
      ),
      const SizedBox(height: 24),
    ],
  );
}

class _WorkingDialog extends StatefulWidget {
  const _WorkingDialog();
  @override
  State<_WorkingDialog> createState() => _WorkingDialogState();
}

class _WorkingDialogState extends State<_WorkingDialog> {
  int _day = 1;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0),
      _end = const TimeOfDay(hour: 16, minute: 0);
  String _time(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  Future<void> _pick(bool start) async {
    final time = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (mounted && time != null) {
      setState(() {
        if (start) {
          _start = time;
        } else {
          _end = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Radno vrijeme'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDropdownFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Dan'),
            items: [
              for (var i = 0; i < 7; i++)
                AppDropdownOption(value: i + 1, label: _days[i]),
            ],
            onChanged: (d) => setState(() => _day = d!),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _pick(true),
            child: Text('Dostupno od ${_time(_start)}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _pick(false),
            child: Text('Dostupno do ${_time(_end)}'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Odustani'),
      ),
      FilledButton(
        onPressed:
            _start.hour * 60 + _start.minute >= _end.hour * 60 + _end.minute
            ? null
            : () => Navigator.pop(
                context,
                WorkingPeriod(_day, _time(_start), _time(_end)),
              ),
        child: const Text('Dodaj'),
      ),
    ],
  );
}
