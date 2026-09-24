import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../progress/domain/usecases/load_progress.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../domain/usecases/cancel_instructor_lesson.dart';
import '../../domain/usecases/confirm_instructor_lesson.dart';
import '../../domain/usecases/complete_instructor_lesson.dart';
import '../../domain/usecases/get_instructor_lesson.dart';
import '../cubit/lesson_detail_cubit.dart';

final class LessonScope extends StatelessWidget {
  const LessonScope({
    required this.lessonId,
    required this.child,
    this.loadProgress = true,
    super.key,
  });
  final String lessonId;
  final Widget child;
  final bool loadProgress;
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      final membership = auth.instructorMembership;
      final token = auth.accessToken;
      if (membership == null || token == null) {
        return const Center(child: Text('Prijavite se za pristup vožnji.'));
      }
      return MultiBlocProvider(
        key: ValueKey('${membership.schoolId}:$token:$lessonId'),
        providers: [
          BlocProvider(
            create: (_) => LessonDetailCubit(
              completeInstructorLesson: getIt<CompleteInstructorLesson>(),
              getInstructorLesson: getIt<GetInstructorLesson>(),
              confirmInstructorLesson: getIt<ConfirmInstructorLesson>(),
              cancelInstructorLesson: getIt<CancelInstructorLesson>(),
              schoolId: membership.schoolId,
              accessToken: token,
              lessonId: lessonId,
            )..load(),
          ),
          BlocProvider(
            create: (_) {
              final cubit = ProgressCubit(
                loadProgress: getIt<LoadProgress>(),
                schoolId: membership.schoolId,
                accessToken: token,
                resource: 'lessons',
                id: lessonId,
              );
              if (loadProgress) cubit.load();
              return cubit;
            },
          ),
        ],
        child: child,
      );
    },
  );
}
