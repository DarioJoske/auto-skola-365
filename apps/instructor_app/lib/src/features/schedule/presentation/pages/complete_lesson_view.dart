import 'dart:async';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/work_page_header.dart';
import '../cubit/lesson_detail_cubit.dart';
import '../cubit/lesson_detail_state.dart';
import '../widgets/instructor_lesson_card.dart';
import '../widgets/lesson_action_listener.dart';

final class CompleteLessonView extends StatefulWidget {
  const CompleteLessonView({super.key});
  @override
  State<CompleteLessonView> createState() => _CompleteLessonViewState();
}

class _CompleteLessonViewState extends State<CompleteLessonView> {
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LessonActionListener(
    onSuccess: (context, state) {
      if (state.lesson?.status == 'COMPLETED') {
        context.replace('/lessons/${state.lesson!.id}/completed');
      }
    },
    child: BlocBuilder<LessonDetailCubit, LessonDetailState>(
      builder: (context, state) {
        final lesson = state.lesson;
        final eligible =
            lesson != null &&
            lesson.status == 'CONFIRMED' &&
            lesson.lessonType == 'DRIVING' &&
            !lesson.endAt.isAfter(DateTime.now());
        return AppPage(
          maxWidth: 720,
          child: ListView(
            children: [
              WorkPageHeader(
                title: 'Završi sat',
                subtitle: lesson == null
                    ? null
                    : '${lesson.candidateName} · ${lessonDate(lesson.startAt)}, ${lessonTime(lesson.startAt)}',
                backPath: lesson == null ? '/home' : '/lessons/${lesson.id}',
              ),
              if (state.isLoading)
                AppLoadingState(isRefreshing: lesson != null),
              if (state.status == LessonDetailStatus.failure)
                AppInlineError(
                  message: state.errorMessage ?? 'Vožnju nije moguće učitati.',
                  onRetry: () => context.read<LessonDetailCubit>().load(),
                ),
              if (lesson != null)
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppListItem(
                        title: lessonStatus(lesson.status),
                        subtitle:
                            '${lessonTime(lesson.startAt)} – ${lessonTime(lesson.endAt)} · ${lesson.categoryCode} kategorija',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Zaključivanjem se evidentira održana vožnja. Broj nastavnih sati izračunava se iz dovršenih vožnji.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _note,
                        enabled:
                            !state.actionInProgress &&
                            lesson.status != 'COMPLETED',
                        maxLines: 4,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Interna bilješka (neobavezno)',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => (value?.trim().length ?? 0) > 2000
                            ? 'Najviše 2000 znakova.'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bilješka je interna i nije vidljiva kandidatu. Evidencija sati osvježava se nakon spremanja.',
                      ),
                      if (!eligible) ...[
                        const SizedBox(height: 16),
                        Text(
                          lesson.status == 'COMPLETED'
                              ? 'Ovaj je sat već evidentiran.'
                              : 'Možete zaključiti samo potvrđenu vožnju nakon završetka termina.',
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed:
                            eligible &&
                                !state.actionInProgress &&
                                !state.isLoading
                            ? () {
                                if (_form.currentState!.validate()) {
                                  context
                                      .read<LessonDetailCubit>()
                                      .completeLesson(
                                        _note.text.trim().isEmpty
                                            ? null
                                            : _note.text.trim(),
                                      );
                                }
                              }
                            : null,
                        child: Text(
                          state.actionInProgress
                              ? 'Spremanje…'
                              : 'Spremi i zaključi',
                        ),
                      ),
                      if (lesson.status == 'COMPLETED')
                        TextButton(
                          onPressed: () => context.replace(
                            '/lessons/${lesson.id}/completed',
                          ),
                          child: const Text('Pregled evidencije'),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: state.actionInProgress
                            ? null
                            : () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/lessons/${lesson.id}');
                                }
                              },
                        child: const Text('Odustani'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
