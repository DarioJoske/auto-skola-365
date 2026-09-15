import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/load_progress.dart';
import '../../domain/usecases/save_progress.dart';
import '../bloc/progress_cubit.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.resource, required this.id, super.key});
  final String resource, id;
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (auth.instructorMembership == null || auth.accessToken == null) {
        return const Center(child: Text('Prijavite se za pregled napretka.'));
      }
      return BlocProvider(
        create: (_) => ProgressCubit(
          loadProgress: getIt<LoadProgress>(),
          saveProgress: getIt<SaveProgress>(),
          schoolId: auth.instructorMembership!.schoolId,
          accessToken: auth.accessToken!,
          resource: resource,
          id: id,
        )..load(),
        child: const ProgressView(),
      );
    },
  );
}

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ProgressCubit, ProgressState>(
    listenWhen: (old, next) => old.eventId != next.eventId,
    listener: (context, state) {
      final failure = state.actionFailure ?? state.loadFailure;
      final expired = failure?.statusCode == 401;
      final message = expired
          ? 'Sesija je istekla. Prijavite se ponovno.'
          : state.actionFailure?.message ?? state.message;
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
      if (expired) context.read<AuthCubit>().logout();
    },
    builder: (context, state) {
      final data = state.data;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/candidates'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Natrag',
              ),
              Expanded(
                child: Text(
                  'Napredak kandidata',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: state.saving
                    ? null
                    : () => context.read<ProgressCubit>().load(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Osvježi',
              ),
            ],
          ),
          if (state.loading)
            const Center(child: CircularProgressIndicator())
          else if (state.loadFailure != null) ...[
            Text(state.loadFailure!.message),
            TextButton(
              onPressed: () => context.read<ProgressCubit>().load(),
              child: const Text('Pokušaj ponovno'),
            ),
          ] else if (data != null) ...[
            Text(
              data.candidateName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (data.skills.isEmpty)
              const Text(
                'Predložak napretka trenutačno je dostupan za B kategoriju.',
              ),
            if (data.editable) ...[
              Text(
                'Procjena za ovaj sat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Odaberite samo vještine koje ste vježbali. Spremanje ažurira procjene ovog sata.',
              ),
              for (final skill in data.skills)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('${data.lessonId}:${skill.code}'),
                    initialValue: state.draft[skill.code],
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: skill.label,
                      hintText: 'Nije procijenjeno na ovom satu',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final status in data.statuses)
                        DropdownMenuItem(
                          value: status.code,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: state.saving
                        ? null
                        : (value) {
                            if (value != null) {
                              context.read<ProgressCubit>().select(
                                skill.code,
                                value,
                              );
                            }
                          },
                  ),
                ),
              FilledButton.icon(
                onPressed: state.saving || state.draft.isEmpty
                    ? null
                    : () => context.read<ProgressCubit>().save(),
                icon: const Icon(Icons.save_outlined),
                label: Text(state.saving ? 'Spremanje…' : 'Spremi napredak'),
              ),
              const SizedBox(height: 24),
            ] else if (data.lessonId != null && data.skills.isNotEmpty)
              const Text(
                'Procjene možete unositi nakon završetka vlastitog sata.',
              ),
            if (data.skills.isNotEmpty) ...[
              Text(
                'Posljednje procjene',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('Prema datumu održanog sata.'),
              for (final skill in data.skills)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(skill.label),
                  subtitle: Text(
                    data.latest(skill.code) == null
                        ? 'Još nije procijenjeno'
                        : '${data.statusLabel(data.latest(skill.code)!.status)} · ${_date(data.latest(skill.code)!.lessonEndAt)}',
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Text(
              'Povijest procjena',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (data.entries.isEmpty)
              const Text('Još nema zabilježenih procjena.'),
            for (final entry in data.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${data.skillLabel(entry.skill)} — ${data.statusLabel(entry.status)}',
                ),
                subtitle: Text(
                  'Sat: ${_date(entry.lessonEndAt)}\nAžurirano: ${_date(entry.recordedAt)}',
                ),
              ),
          ],
        ],
      );
    },
  );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}. ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
