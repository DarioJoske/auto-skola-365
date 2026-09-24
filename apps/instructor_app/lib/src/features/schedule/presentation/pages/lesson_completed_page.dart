import 'package:flutter/material.dart';
import '../widgets/lesson_scope.dart';
import 'lesson_completed_view.dart';

final class LessonCompletedPage extends StatelessWidget {
  const LessonCompletedPage({required this.lessonId, super.key});
  final String lessonId;
  @override
  Widget build(BuildContext context) => LessonScope(
    lessonId: lessonId,
    loadProgress: true,
    child: const LessonCompletedView(),
  );
}
