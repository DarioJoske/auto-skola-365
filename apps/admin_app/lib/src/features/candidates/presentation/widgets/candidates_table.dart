import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/candidate.dart';
import '../pages/candidate_presentation.dart';

final class CandidatesTable extends StatefulWidget {
  const CandidatesTable({required this.candidates, super.key});
  final List<Candidate> candidates;
  @override
  State<CandidatesTable> createState() => _CandidatesTableState();
}

final class _CandidatesTableState extends State<CandidatesTable> {
  static const _pageSize = 10;
  int _page = 0;
  @override
  void didUpdateWidget(covariant CandidatesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates != widget.candidates) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) return const SizedBox.shrink();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.candidates.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          showBorder: false,
          child: LayoutBuilder(
            builder: (context, constraints) => AppHorizontalScroll(
              minWidth: constraints.maxWidth,
              child: SizedBox(
                width: constraints.maxWidth < 1000
                    ? 1000
                    : constraints.maxWidth,
                child: Column(
                  children: [
                    const _TableRow(
                      header: true,
                      cells: [
                        Text('Ime i prezime'),
                        Text('Kategorija'),
                        Text('Instruktor'),
                        Text('Sati vožnje'),
                        Text('Status'),
                      ],
                    ),
                    for (final candidate in widget.candidates.sublist(
                      start,
                      end,
                    ))
                      _TableRow(
                        onTap: () => context.go('/candidates/${candidate.id}'),
                        cells: [
                          Text(
                            candidate.fullName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(candidate.categoryCode),
                          Text(
                            candidate.assignedInstructorName ??
                                'Nije dodijeljen',
                          ),
                          Text(
                            candidate.completedDrivingHours == null
                                ? 'Nije dostupno'
                                : candidate.requiredDrivingHours == null
                                ? '${candidate.completedDrivingHours} · bez cilja'
                                : '${candidate.completedDrivingHours} / ${candidate.requiredDrivingHours}',
                          ),
                          AppStatusBadge(
                            label: candidateStatusLabel(candidate.status),
                            tone: candidateStatusTone(candidate.status),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            Text(
              'Prikazano ${start + 1}–$end od ${widget.candidates.length} kandidata',
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stranica ${_page + 1} od ${(widget.candidates.length / _pageSize).ceil()}',
                ),
                IconButton(
                  tooltip: 'Prethodna stranica',
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Sljedeća stranica',
                  onPressed: end < widget.candidates.length
                      ? () => setState(() => _page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

final class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, this.header = false, this.onTap});
  final List<Widget> cells;
  final bool header;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: header
        ? Theme.of(context).colorScheme.surfaceContainer
        : Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DefaultTextStyle.merge(
          style: header
              ? Theme.of(context).textTheme.labelLarge
              : Theme.of(context).textTheme.bodyMedium,
          child: Row(
            children: [
              for (final (i, cell) in cells.indexed)
                Expanded(
                  flex: const [26, 12, 21, 16, 18][i],
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: cell,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
