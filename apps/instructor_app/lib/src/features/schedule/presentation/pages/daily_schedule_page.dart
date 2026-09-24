import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/list_instructor_lessons.dart';
import '../cubit/daily_schedule_cubit.dart';
import 'daily_schedule_view.dart';

final class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      final membership = auth.instructorMembership;
      final token = auth.accessToken;
      if (membership == null || token == null) {
        return const Center(child: Text('Prijavite se za pristup rasporedu.'));
      }
      return BlocProvider(
        key: ValueKey('${membership.schoolId}:$token'),
        create: (_) => DailyScheduleCubit(
          listLessons: getIt<ListInstructorLessons>(),
          schoolId: membership.schoolId,
          accessToken: token,
        )..load(),
        child: const DailyScheduleView(),
      );
    },
  );
}
