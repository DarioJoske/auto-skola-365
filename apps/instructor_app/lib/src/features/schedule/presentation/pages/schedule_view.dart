import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/schedule_cubit.dart';
import '../cubit/schedule_state.dart';
import '../widgets/instructor_lesson_card.dart';
import '../widgets/reserve_lesson_button.dart';

const _lessonStatuses = [
  'REQUESTED',
  'CONFIRMED',
  'COMPLETED',
  'CANCELLED',
  'NO_SHOW',
];
String _statusLabel(String value) => lessonStatus(value);
String _formatRangeLabel(DateTime date, ScheduleRangeMode mode) {
  final start = mode == ScheduleRangeMode.day
      ? date
      : DateTime(date.year, date.month, date.day - date.weekday + 1);
  return mode == ScheduleRangeMode.day
      ? lessonDate(start)
      : '${lessonDate(start)} – ${lessonDate(DateTime(start.year, start.month, start.day + 6))}';
}

final class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});
  Future<void> _pickDate(BuildContext context, DateTime selected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date != null && context.mounted) {
      context.read<ScheduleCubit>().selectDate(date);
    }
  }

  Future<void> _open(BuildContext context, String id) async {
    await context.push('/lessons/$id');
    if (context.mounted) context.read<ScheduleCubit>().load();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<ScheduleCubit, ScheduleState>(
    listenWhen: (a, b) => a.errorEventId != b.errorEventId,
    listener: (context, state) {
      if (state.errorStatusCode == 401) {
        showSessionExpired(context);
        context.read<AuthCubit>().logout();
      }
    },
    child: BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) => AppPage(
        maxWidth: 720,
        child: RefreshIndicator(
          onRefresh: context.read<ScheduleCubit>().load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.lessons.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScheduleHeader(
                      selectedDate: state.selectedDate,
                      rangeMode: state.rangeMode,
                      instructorName: context
                          .read<AuthCubit>()
                          .state
                          .user
                          ?.fullName,
                      onPreviousDay: () =>
                          context.read<ScheduleCubit>().moveByDays(-1),
                      onNextDay: () =>
                          context.read<ScheduleCubit>().moveByDays(1),
                      onRefresh: () => context.read<ScheduleCubit>().load(),
                      onPickDate: () => _pickDate(context, state.selectedDate),
                    ),
                    const SizedBox(height: 16),
                    _ScheduleFilters(
                      status: state.filters.status,
                      rangeMode: state.rangeMode,
                    ),
                    const SizedBox(height: 16),
                    ReserveLessonButton(
                      date: state.selectedDate,
                      onSaved: () => context.read<ScheduleCubit>().load(),
                    ),
                    const SizedBox(height: 16),
                    if (state.isLoading)
                      AppLoadingState(isRefreshing: state.lessons.isNotEmpty),
                    if (state.status == ScheduleStatus.failure)
                      AppInlineError(
                        message:
                            state.errorMessage ??
                            'Raspored nije moguće učitati.',
                        onRetry: () => context.read<ScheduleCubit>().load(),
                      ),
                    if (state.lessons.isEmpty &&
                        !state.isLoading &&
                        state.status != ScheduleStatus.failure)
                      const AppEmptyState(
                        title: 'Nema termina',
                        message: 'Za odabrano razdoblje i status nema vožnji.',
                      ),
                  ],
                );
              }
              if (index == state.lessons.length + 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton(
                    onPressed: () => context.push('/availability'),
                    child: const Text('Uredi dostupnost'),
                  ),
                );
              }
              final lesson = state.lessons[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InstructorLessonCard(
                  lesson: lesson,
                  showDate: state.rangeMode == ScheduleRangeMode.week,
                  onTap: () => _open(context, lesson.id),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
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
          'Moj raspored',
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
        AppDropdownFormField<String>(
          initialValue: status,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(Icons.filter_alt_outlined),
          ),
          items: [
            const AppDropdownOption(value: null, label: 'Svi statusi'),
            ..._lessonStatuses.map(
              (status) =>
                  AppDropdownOption(value: status, label: _statusLabel(status)),
            ),
          ],
          onChanged: (value) =>
              context.read<ScheduleCubit>().filterStatus(value),
        ),
      ],
    );
  }
}
