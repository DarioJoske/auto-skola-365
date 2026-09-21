import '../../domain/entities/lesson_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../candidates/domain/usecases/list_candidates.dart';
import '../../../instructors/domain/usecases/list_instructors.dart';
import '../../domain/usecases/cancel_lesson.dart';
import '../../domain/usecases/confirm_lesson.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/list_lessons.dart';
import '../../domain/usecases/update_lesson.dart';
import '../cubit/lessons_cubit.dart';

import 'lessons_view.dart';

final class LessonsPage extends StatelessWidget {
  const LessonsPage({
    this.initialFilters,
    this.openCreateOnLoad = false,
    required this.listLessons,
    required this.createLesson,
    required this.updateLesson,
    required this.confirmLesson,
    required this.cancelLesson,
    required this.listCandidates,
    required this.listInstructors,
    super.key,
  });

  final LessonFilters? initialFilters;
  final bool openCreateOnLoad;
  final ListLessons listLessons;
  final CreateLessonUseCase createLesson;
  final UpdateLessonUseCase updateLesson;
  final ConfirmLessonUseCase confirmLesson;
  final CancelLessonUseCase cancelLesson;
  final ListCandidates listCandidates;
  final ListInstructors listInstructors;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final membership = authState.user!.primaryMembership!;

    return BlocProvider(
      create: (_) => LessonsCubit(
        initialFilters: initialFilters,
        listLessons: listLessons,
        createLesson: createLesson,
        updateLesson: updateLesson,
        confirmLesson: confirmLesson,
        cancelLesson: cancelLesson,
        listCandidates: listCandidates,
        listInstructors: listInstructors,
        schoolId: membership.schoolId,
        accessToken: authState.accessToken!,
      )..load(),
      child: LessonsView(openCreateOnLoad: openCreateOnLoad),
    );
  }
}
