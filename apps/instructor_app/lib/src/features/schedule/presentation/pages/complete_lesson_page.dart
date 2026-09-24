import 'package:flutter/material.dart';
import '../widgets/lesson_scope.dart';
import 'complete_lesson_view.dart';

final class CompleteLessonPage extends StatelessWidget {
  const CompleteLessonPage({required this.lessonId, super.key});
  final String lessonId;
  @override
  Widget build(BuildContext context) => LessonScope(
    lessonId: lessonId,
    loadProgress: false,
    child: const CompleteLessonView(),
  );
}
