import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../../../../core/widgets/work_page_header.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/usecases/decide_request.dart';
import '../cubit/request_cubit.dart';
import '../cubit/lesson_detail_state.dart';
import '../widgets/instructor_lesson_card.dart';

final class RequestView extends StatefulWidget {
  const RequestView({super.key});
  @override
  State<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends State<RequestView> {
  DateTime? _proposed;
  Future<void> _pick() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _proposed ?? now.add(const Duration(days: 1)),
    );
    if (!mounted || day == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (!mounted || time == null) return;
    setState(
      () => _proposed = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odbiti zahtjev?'),
        content: const Text('Zahtjev će biti zatvoren bez upisa sati.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odbij'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<RequestCubit>().decide(RequestDecision.reject);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RequestCubit, LessonDetailState>(
    listenWhen: (a, b) =>
        a.errorEventId != b.errorEventId ||
        a.successEventId != b.successEventId,
    listener: (context, state) {
      if (state.errorStatusCode == 401) {
        showSessionExpired(context);
        context.read<AuthCubit>().logout();
      } else if (state.errorMessage != null &&
          state.status != LessonDetailStatus.failure) {
        showAppSnackBar(context, state.errorMessage!);
      } else if (state.successMessage != null) {
        showAppSnackBar(context, state.successMessage!);
        setState(() => _proposed = null);
      }
    },
    builder: (context, state) => AppPage(
      maxWidth: 720,
      child: ListView(
        children: [
          WorkPageHeader(
            title: 'Zahtjev termina',
            subtitle: state.lesson?.candidateName,
            backPath: '/home',
            onRefresh: () => context.read<RequestCubit>().load(),
          ),
          if (state.isLoading)
            AppLoadingState(isRefreshing: state.lesson != null),
          if (state.status == LessonDetailStatus.failure)
            AppInlineError(
              message: state.errorMessage!,
              onRetry: () => context.read<RequestCubit>().load(),
            ),
          if (state.lesson case final lesson?) ...[
            Text(
              lessonDate(lesson.startAt),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            InstructorLessonCard(lesson: lesson),
            const SizedBox(height: 16),
            if (lesson.notes != null)
              AppCard(child: Text('Napomena: ${lesson.notes}')),
            const SizedBox(height: 16),
            if (lesson.proposedStartAt case final proposed?) ...[
              AppStatusBadge(
                label: 'Čeka odgovor kandidata',
                tone: AppTone.warning,
              ),
              const SizedBox(height: 12),
              Text(
                'Predloženo: ${lessonDate(proposed)} · ${lessonTime(proposed)}',
              ),
              const SizedBox(height: 16),
            ],
            if (lesson.status == 'REQUESTED') ...[
              const Text(
                'Vožnja je dogovorena tek nakon potvrde. Dostupnost se ponovno provjerava pri spremanju.',
              ),
              const SizedBox(height: 24),
              if (lesson.proposedStartAt == null)
                FilledButton(
                  onPressed: state.actionInProgress
                      ? null
                      : () => context.read<RequestCubit>().decide(
                          RequestDecision.confirm,
                        ),
                  child: const Text('Potvrdi termin'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: state.actionInProgress ? null : _pick,
                child: const Text('Predloži drugo vrijeme'),
              ),
              if (_proposed case final start?) ...[
                const SizedBox(height: 12),
                Text('${lessonDate(start)} · ${lessonTime(start)} · 60 minuta'),
                FilledButton(
                  onPressed: state.actionInProgress
                      ? null
                      : () => context.read<RequestCubit>().decide(
                          RequestDecision.propose,
                          startAt: start,
                        ),
                  child: const Text('Pošalji prijedlog'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: state.actionInProgress ? null : _reject,
                child: const Text('Odbij zahtjev'),
              ),
            ] else
              const Text('Zahtjev je obrađen.'),
          ],
          if (state.actionInProgress) const LinearProgressIndicator(),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
