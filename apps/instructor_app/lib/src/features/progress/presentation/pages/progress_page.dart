import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/load_progress.dart';
import '../bloc/progress_cubit.dart';
import '../widgets/driving_hours_panel.dart';

final class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.resource, required this.id, super.key});

  final String resource;
  final String id;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (auth.instructorMembership == null || auth.accessToken == null) {
        return const Center(
          child: Text('Prijavite se za pregled odrađenih sati.'),
        );
      }
      return BlocProvider(
        key: ValueKey('${auth.instructorMembership!.schoolId}:$resource:$id'),
        create: (_) => ProgressCubit(
          loadProgress: getIt<LoadProgress>(),
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

final class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => context.read<ProgressCubit>().load(),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/candidates'),
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
              onPressed: () => context.read<ProgressCubit>().load(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Osvježi',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const DrivingHoursPanel(),
      ],
    ),
  );
}
