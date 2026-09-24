import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/lesson_detail_cubit.dart';
import '../cubit/lesson_detail_state.dart';

final class LessonActionListener extends StatelessWidget {
  const LessonActionListener({required this.child, this.onSuccess, super.key});
  final Widget child;
  final void Function(BuildContext, LessonDetailState)? onSuccess;
  @override
  Widget build(BuildContext context) =>
      BlocListener<LessonDetailCubit, LessonDetailState>(
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
            onSuccess?.call(context, state);
          }
        },
        child: child,
      );
}
