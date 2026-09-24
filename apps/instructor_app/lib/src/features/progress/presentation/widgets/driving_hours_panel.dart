import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../bloc/progress_cubit.dart';

final class DrivingHoursPanel extends StatelessWidget {
  const DrivingHoursPanel({this.emphasized = false, super.key});
  final bool emphasized;

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.loading && data == null) const AppLoadingState(),
          if (state.loadFailure != null)
            AppInlineError(
              message: state.loadFailure!.statusCode == 401
                  ? 'Sesija je istekla. Prijavite se ponovno.'
                  : state.loadFailure!.message,
              onRetry: () => context.read<ProgressCubit>().load(),
            ),
          if (data != null)
            if (emphasized)
              AppProgressCard(
                title: 'EVIDENCIJA VOŽNJE',
                valueLabel: hasTarget
                    ? '${data.completedDrivingHours} / $target'
                    : '${data.completedDrivingHours}',
                subtitle: 'evidentiranih školskih sati · ${data.categoryCode}',
                message: hasTarget
                    ? 'Spremnost za ispit procjenjuje instruktor.'
                    : 'Cilj sati nije postavljen. Spremnost za ispit procjenjuje instruktor.',
                progress: hasTarget
                    ? data.completedDrivingHours / target
                    : null,
                isLoading: state.loading,
              )
            else
              AppListItem(
                leading: CircleAvatar(
                  child: Text('${data.completedDrivingHours}'),
                ),
                title: hasTarget
                    ? '${data.completedDrivingHours}/$target sati odrađeno'
                    : '${data.completedDrivingHours} sati odrađeno',
                subtitle: '${data.candidateName} · ${data.categoryCode}',
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      hasTarget
                          ? 'Broje se samo dovršene vožnje.'
                          : 'Cilj sati nije postavljen.',
                    ),
                    if (hasTarget || state.loading) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.loading
                            ? null
                            : (data.completedDrivingHours / target!).clamp(
                                0.0,
                                1.0,
                              ),
                      ),
                    ],
                  ],
                ),
              ),
        ],
      );
    },
  );
}
