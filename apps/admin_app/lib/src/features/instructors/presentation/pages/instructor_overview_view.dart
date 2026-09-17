import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/instructor_overview.dart';
import '../cubit/instructor_overview_cubit.dart';
import '../cubit/instructor_overview_state.dart';

final class InstructorOverviewView extends StatefulWidget {
  const InstructorOverviewView({this.initialQuery = '', super.key});
  final String initialQuery;
  @override
  State<InstructorOverviewView> createState() => _InstructorOverviewViewState();
}

class _InstructorOverviewViewState extends State<InstructorOverviewView> {
  late final _query = TextEditingController(text: widget.initialQuery);
  bool? _active;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() =>
      context.read<InstructorOverviewCubit>().search(_query.text, _active);
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<InstructorOverviewCubit, InstructorOverviewState>(
    listenWhen: (previous, current) =>
        previous.errorEventId != current.errorEventId,
    listener: (context, state) {
      if (state.failure?.statusCode == 401) {
        showSessionExpired(context);
        context.read<AuthCubit>().logout();
      }
    },
    builder: (context, state) => CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _InstructorHeader(),
              const SizedBox(height: 24),
              _InstructorFilters(
                controller: _query,
                active: _active,
                onSearch: _search,
                onActiveChanged: (value) {
                  setState(() => _active = value);
                  _search();
                },
              ),
              const SizedBox(height: 24),
              if (state.isLoading)
                AppLoadingState(isRefreshing: state.data != null),
              if (state.failure != null)
                AppInlineError(
                  message: state.failure!.message,
                  onRetry: context.read<InstructorOverviewCubit>().load,
                ),
              if (state.data case final data?) ...[
                Text(
                  '${data.weekStart} – ${data.weekEnd} · ${data.timeZone}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Opterećenje: trajanje termina sa statusom Potvrđeno koji počinju u ovom tjednu (ponedjeljak – nedjelja). Završeni i otkazani termini nisu uključeni. Dodijeljeni kandidati obuhvaćaju sve statuse.',
                ),
                const SizedBox(height: 16),
                if (data.instructors.isEmpty &&
                    !state.isLoading &&
                    state.failure == null)
                  const AppEmptyState(
                    title: 'Nema instruktora',
                    message:
                        'Nema rezultata za odabranu pretragu. Promijeni pretragu ili dodaj instruktora.',
                  ),
                if (data.instructors.isNotEmpty) _InstructorTable(data: data),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _InstructorTable extends StatelessWidget {
  const _InstructorTable({required this.data});
  final InstructorOverview data;
  @override
  Widget build(BuildContext context) => AppCard(
    child: AppHorizontalScroll(
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.surfaceContainer,
        ),
        dataRowMinHeight: 72,
        dataRowMaxHeight: 110,
        columns: const [
          DataColumn(label: Text('Instruktor')),
          DataColumn(label: Text('Kategorije')),
          DataColumn(label: Text('Kandidati')),
          DataColumn(label: Text('Ovaj tjedan')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Akcije')),
        ],
        rows: [
          for (final instructor in data.instructors)
            DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(instructor.name),
                      Text(
                        instructor.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                DataCell(Text(instructor.categoryCodes.join(', '))),
                DataCell(
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _AssignedCandidates(instructor: instructor),
                    ),
                    child: Text('${instructor.candidates.length} dodijeljenih'),
                  ),
                ),
                DataCell(
                  Text(
                    '${instructor.confirmedMinutes ~/ 60} h ${instructor.confirmedMinutes % 60} min\n${instructor.confirmedLessons} termina',
                  ),
                ),
                DataCell(
                  AppStatusBadge(
                    label: instructor.active ? 'Aktivan' : 'Neaktivan',
                    tone: instructor.active ? AppTone.success : AppTone.neutral,
                  ),
                ),
                DataCell(
                  TextButton(
                    onPressed: () => context.go(
                      Uri(
                        path: '/lessons',
                        queryParameters: {
                          'instructorId': instructor.id,
                          'date': data.weekStart,
                          'status': 'CONFIRMED',
                        },
                      ).toString(),
                    ),
                    child: const Text('Raspored'),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _AssignedCandidates extends StatelessWidget {
  const _AssignedCandidates({required this.instructor});
  final InstructorSummary instructor;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Kandidati · ${instructor.name}'),
    content: SizedBox(
      width: 540,
      height: 360,
      child: instructor.candidates.isEmpty
          ? const Text('Instruktor nema dodijeljenih kandidata.')
          : ListView.separated(
              itemCount: instructor.candidates.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final candidate = instructor.candidates[index];
                return ListTile(
                  title: Text(candidate.name),
                  subtitle: Text(
                    '${candidate.categoryCode} · ${_statusLabel(candidate.status)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.pop();
                    context.go(
                      Uri(
                        path: '/candidates',
                        queryParameters: {
                          'query': candidate.name,
                          'instructorId': instructor.id,
                        },
                      ).toString(),
                    );
                  },
                );
              },
            ),
    ),
    actions: [
      TextButton(onPressed: () => context.pop(), child: const Text('Zatvori')),
    ],
  );
}

String _statusLabel(String status) => switch (status) {
  'LEAD' => 'Potencijalni kandidat',
  'ENROLLED' => 'Upisan',
  'IN_THEORY' => 'Na teoriji',
  'PASSED_THEORY' => 'Položio teoriju',
  'IN_DRIVING' => 'Na vožnji',
  'READY_FOR_EXAM' => 'Spreman za ispit',
  'EXAM_SCHEDULED' => 'Ispit zakazan',
  'PASSED' => 'Položio',
  'DROPPED' => 'Odustao',
  'ARCHIVED' => 'Arhiviran',
  _ => status,
};

class _InstructorHeader extends StatelessWidget {
  const _InstructorHeader();
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 16,
    runSpacing: 12,
    children: [
      Text('Instruktori', style: Theme.of(context).textTheme.headlineLarge),
      OutlinedButton.icon(
        onPressed: () => context.go('/instructors/manage'),
        icon: const Icon(Icons.manage_accounts),
        label: const Text('Dodaj ili uredi instruktora'),
      ),
    ],
  );
}

class _InstructorFilters extends StatelessWidget {
  const _InstructorFilters({
    required this.controller,
    required this.active,
    required this.onSearch,
    required this.onActiveChanged,
  });
  final TextEditingController controller;
  final bool? active;
  final VoidCallback onSearch;
  final ValueChanged<bool?> onActiveChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 360,
        child: TextField(
          controller: controller,
          onSubmitted: (_) => onSearch(),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            labelText: 'Pretraži instruktore',
            hintText: 'Ime ili e-mail',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      SizedBox(
        width: 220,
        child: DropdownButtonFormField<bool?>(
          initialValue: active,
          isExpanded: true,
          itemHeight: null,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Svi instruktori')),
            DropdownMenuItem(value: true, child: Text('Aktivni')),
            DropdownMenuItem(value: false, child: Text('Neaktivni')),
          ],
          onChanged: onActiveChanged,
        ),
      ),
      FilledButton(onPressed: onSearch, child: const Text('Pretraži')),
      IconButton(
        tooltip: 'Osvježi instruktore',
        onPressed: context.read<InstructorOverviewCubit>().load,
        icon: const Icon(Icons.refresh),
      ),
    ],
  );
}
