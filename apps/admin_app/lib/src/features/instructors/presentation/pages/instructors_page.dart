import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/usecases/create_instructor.dart';
import '../../domain/usecases/list_instructors.dart';
import '../../domain/usecases/update_instructor.dart';
import '../cubit/instructors_cubit.dart';
import 'instructors_view.dart';

final class InstructorsPage extends StatelessWidget {
  const InstructorsPage({
    required this.listInstructors,
    required this.createInstructor,
    required this.updateInstructor,
    super.key,
  });

  final ListInstructors listInstructors;
  final CreateInstructorUseCase createInstructor;
  final UpdateInstructorUseCase updateInstructor;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final membership = authState.user!.primaryMembership!;

    return BlocProvider(
      create: (_) => InstructorsCubit(
        listInstructors: listInstructors,
        createInstructor: createInstructor,
        updateInstructor: updateInstructor,
        schoolId: membership.schoolId,
        accessToken: authState.accessToken!,
      )..load(),
      child: const InstructorsView(),
    );
  }
}
