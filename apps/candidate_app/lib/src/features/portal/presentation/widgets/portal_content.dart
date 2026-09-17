import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/candidate_portal.dart';
import '../cubit/portal_cubit.dart';
import '../cubit/portal_state.dart';

final class PortalContent extends StatelessWidget {
  const PortalContent({required this.builder, super.key});
  final Widget Function(BuildContext, CandidatePortal) builder;
  @override
  Widget build(BuildContext context) => BlocBuilder<PortalCubit, PortalState>(
    builder: (context, state) {
      if (state.data == null && (state.loading || state.loadFailure == null)) {
        return const AppLoadingState();
      }
      return RefreshIndicator(
        onRefresh: () => context.read<PortalCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.loading) ...[
                    const AppLoadingState(isRefreshing: true),
                    const SizedBox(height: 16),
                  ],
                  if (state.loadFailure != null) ...[
                    AppInlineError(
                      message: state.loadFailure!.message,
                      onRetry: () => context.read<PortalCubit>().load(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.data != null)
                    KeyedSubtree(
                      key: const ValueKey('portal-data'),
                      child: builder(context, state.data!),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
