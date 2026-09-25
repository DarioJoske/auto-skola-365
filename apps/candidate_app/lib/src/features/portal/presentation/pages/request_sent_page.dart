import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../cubit/portal_cubit.dart';
import '../cubit/portal_state.dart';
import '../utils/lesson_formatters.dart';

final class RequestSentPage extends StatelessWidget {
  const RequestSentPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<PortalCubit, PortalState>(
    builder: (context, state) => AppPage(
      maxWidth: 720,
      child: ListView(
        children: [
          Text(
            state.lastRequestedStart == null
                ? 'Pregled zahtjeva'
                : 'Zahtjev je poslan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (state.lastRequestedStart case final start?) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(
                label: 'Zahtjev zaprimljen',
                tone: AppTone.warning,
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonDate(context, start),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${lessonTime(context, start)} · 60 minuta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Predloženi termin još nije potvrđena vožnja. Aktualno stanje provjeri u svojim terminima.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(state.data?.instructorName ?? 'Tvoj instruktor'),
                subtitle: const Text('Odgovor provjeri u popisu termina.'),
              ),
            ),
          ] else
            const Text(
              'Otvaranje ove stranice ne šalje zahtjev. Svoje zahtjeve možeš provjeriti u terminima.',
            ),
          if (state.loadFailure != null)
            AppInlineError(
              message: state.loadFailure!.message,
              onRetry: () => context.read<PortalCubit>().load(),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/lessons'),
            child: const Text('Povratak na termine'),
          ),
        ],
      ),
    ),
  );
}
