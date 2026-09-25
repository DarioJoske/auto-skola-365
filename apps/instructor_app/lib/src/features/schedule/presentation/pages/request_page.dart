import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/usecases/get_instructor_lesson.dart';
import '../../domain/usecases/decide_request.dart';
import '../cubit/request_cubit.dart';
import 'request_view.dart';

final class RequestPage extends StatelessWidget {
  const RequestPage({required this.lessonId, super.key});
  final String lessonId;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth.instructorMembership == null || auth.accessToken == null) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      key: ValueKey('${auth.accessToken}:$lessonId'),
      create: (_) => RequestCubit(
        load: getIt<GetInstructorLesson>(),
        decide: getIt<DecideRequest>(),
        schoolId: auth.instructorMembership!.schoolId,
        accessToken: auth.accessToken!,
        lessonId: lessonId,
      )..load(),
      child: const RequestView(),
    );
  }
}
