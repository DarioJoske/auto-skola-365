import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../widgets/portal_content.dart';
import '../widgets/lesson_card.dart';
import '../widgets/request_lesson_dialog.dart';

final class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});
  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  bool _history = false;
  @override
  Widget build(BuildContext context) => PortalContent(
    builder: (context, data) {
      final items = _history
          ? data.historyAt(DateTime.now())
          : data.upcomingAt(DateTime.now());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Tvoji termini',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              FilledButton.icon(
                onPressed: data.canRequestLesson
                    ? () => showLessonRequest(context)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Zatraži termin'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Nadolazeći')),
                ButtonSegment(value: true, label: Text('Povijest')),
              ],
              selected: {_history},
              onSelectionChanged: (values) =>
                  setState(() => _history = values.single),
            ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            AppEmptyState(
              title: _history
                  ? 'Još nema povijesti vožnji'
                  : 'Nema nadolazećih termina',
              message: 'Ovdje ćeš vidjeti svoje termine i njihov status.',
            ),
          for (final item in items) ...[
            LessonCard(lesson: item),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}
