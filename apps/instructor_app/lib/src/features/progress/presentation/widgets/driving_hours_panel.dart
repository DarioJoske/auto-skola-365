import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../bloc/progress_cubit.dart';

final class DrivingHoursPanel extends StatelessWidget {
  const DrivingHoursPanel({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ProgressCubit, ProgressState>(
    listenWhen: (previous, current) => previous.eventId != current.eventId,
    listener: (context, state) {
      if (state.loadFailure?.statusCode == 401) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Sesija je istekla. Prijavite se ponovno.'),
            ),
          );
        context.read<AuthCubit>().logout();
      }
    },
    builder: (context, state) {
      final data = state.data;
      final target = data?.requiredDrivingHours;
      final hasTarget = target != null && target > 0;
      final colors = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Odrađeni sati vožnje', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              if (state.loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              if (state.loadFailure != null) ...[
                Text(
                  state.loadFailure!.statusCode == 401
                      ? 'Sesija je istekla. Prijavite se ponovno.'
                      : state.loadFailure!.message,
                  style: TextStyle(color: colors.error),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: state.loading
                        ? null
                        : () => context.read<ProgressCubit>().load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovno'),
                  ),
                ),
              ],
              if (data != null) ...[
                Text(
                  '${data.candidateName} · ${data.categoryCode}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  hasTarget
                      ? '${data.completedDrivingHours}/$target sati odrađeno'
                      : '${data.completedDrivingHours} sati odrađeno',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasTarget) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (data.completedDrivingHours / target).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    semanticsLabel: 'Odrađeni nastavni sati',
                    semanticsValue: '${data.completedDrivingHours} od $target',
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text('Cilj sati nije postavljen.'),
                ],
                const SizedBox(height: 12),
                Text(
                  'Broje se samo dovršene vožnje.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
