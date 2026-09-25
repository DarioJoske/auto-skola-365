import '../../domain/usecases/respond_proposal.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/portal_navigation.dart';
import '../cubit/portal_state.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/load_portal.dart';
import '../../domain/usecases/request_lesson.dart';
import '../cubit/portal_cubit.dart';

final class PortalShell extends StatelessWidget {
  const PortalShell({required this.path, required this.child, super.key});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      if (!auth.isAuthenticated || auth.candidateMembership == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return BlocProvider(
        key: ValueKey('${auth.user!.id}:${auth.candidateMembership!.schoolId}'),
        create: (_) => PortalCubit(
          respondProposal: getIt<RespondProposal>(),
          loadPortal: getIt<LoadPortal>(),
          requestLesson: getIt<RequestLesson>(),
          schoolId: auth.candidateMembership!.schoolId,
          accessToken: auth.accessToken!,
        )..load(),
        child: BlocListener<PortalCubit, PortalState>(
          listenWhen: (previous, current) =>
              previous.errorId != current.errorId ||
              previous.responseId != current.responseId,
          listener: (context, state) {
            final failure = state.actionFailure ?? state.loadFailure;
            if (failure?.statusCode == 401) {
              showSessionExpired(context);
              context.read<AuthCubit>().logout();
            } else if (state.actionFailure != null) {
              showAppSnackBar(context, state.actionFailure!.message);
            } else if (failure == null &&
                state.responseId > 0 &&
                !state.loading &&
                !state.saving) {
              showAppSnackBar(context, 'Odgovor je spremljen.');
            }
          },
          child: PortalNavigation(path: path, child: child),
        ),
      );
    },
  );
}
