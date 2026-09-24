import 'package:auto_skola_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/instructor_candidate.dart';
import '../cubit/instructor_candidates_cubit.dart';
import '../cubit/instructor_candidates_state.dart';

const _candidateStatuses = [
  'LEAD',
  'ENROLLED',
  'IN_THEORY',
  'PASSED_THEORY',
  'IN_DRIVING',
  'READY_FOR_EXAM',
  'EXAM_SCHEDULED',
  'PASSED',
  'DROPPED',
  'ARCHIVED',
];

const _categoryCodes = ['A', 'B', 'C', 'CE', 'D'];

String _statusLabel(String status) {
  return switch (status) {
    'LEAD' => 'Novi kontakt',
    'ENROLLED' => 'Upisan',
    'IN_THEORY' => 'Teorija',
    'PASSED_THEORY' => 'Polozena teorija',
    'IN_DRIVING' => 'Voznja',
    'READY_FOR_EXAM' => 'Spreman za ispit',
    'EXAM_SCHEDULED' => 'Ispit zakazan',
    'PASSED' => 'Polozio',
    'DROPPED' => 'Odustao',
    'ARCHIVED' => 'Arhiviran',
    _ => status,
  };
}

class InstructorCandidatesView extends StatefulWidget {
  const InstructorCandidatesView({super.key});

  @override
  State<InstructorCandidatesView> createState() =>
      _InstructorCandidatesViewState();
}

class _InstructorCandidatesViewState extends State<InstructorCandidatesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _searchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InstructorCandidatesCubit, InstructorCandidatesState>(
      listenWhen: (previous, current) =>
          previous.errorEventId != current.errorEventId &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorStatusCode == 401) {
          showSessionExpired(context);
        } else {
          showAppSnackBar(context, state.errorMessage!);
        }
        if (state.errorStatusCode == 401) {
          context.read<AuthCubit>().logout();
        }
      },
      child: BlocBuilder<InstructorCandidatesCubit, InstructorCandidatesState>(
        builder: (context, state) {
          return AppPage(
            maxWidth: 720,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              onRefresh: () => context.read<InstructorCandidatesCubit>().load(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: [
                        _CandidatesHeader(
                          count: state.candidates.length,
                          isLoading: state.isLoading,
                          onRefresh: () =>
                              context.read<InstructorCandidatesCubit>().load(),
                        ),
                        if (state.isLoading)
                          AppLoadingState(
                            isRefreshing: state.candidates.isNotEmpty,
                          ),
                        const SizedBox(height: 16),
                        _CandidatesFilters(
                          searchController: _searchController,
                          state: state,
                        ),
                        const SizedBox(height: 12),
                        if (state.status == InstructorCandidatesStatus.failure)
                          AppInlineError(
                            message:
                                state.errorMessage ??
                                'Kandidate nije moguce ucitati.',
                            onRetry: () => context
                                .read<InstructorCandidatesCubit>()
                                .load(),
                          ),
                        if (state.candidates.isEmpty &&
                            !state.isLoading &&
                            state.status != InstructorCandidatesStatus.failure)
                          _EmptyCandidates(
                            hasActiveFilter: state.filters.isActive,
                          ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: state.candidates.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CandidateCard(
                          candidate: state.candidates[index],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CandidatesHeader extends StatelessWidget {
  const _CandidatesHeader({
    required this.count,
    required this.isLoading,
    required this.onRefresh,
  });

  final int count;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moji kandidati',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLoading ? 'Ucitavanje...' : '$count dodijeljenih kandidata',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Osvjezi kandidate',
        ),
      ],
    );
  }
}

class _CandidatesFilters extends StatelessWidget {
  const _CandidatesFilters({
    required this.searchController,
    required this.state,
  });

  final TextEditingController searchController;
  final InstructorCandidatesState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Pretraži kandidate',
            hintText: 'Ime, email, telefon ili OIB',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      context.read<InstructorCandidatesCubit>().search('');
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Ocisti pretragu',
                  ),
          ),
          onSubmitted: (value) =>
              context.read<InstructorCandidatesCubit>().search(value),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Filtri'),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final statusFilter = _StatusFilter(value: state.filters.status);
                final categoryFilter = _CategoryFilter(
                  value: state.filters.categoryCode,
                );

                if (constraints.maxWidth < 560) {
                  return Column(
                    children: [
                      statusFilter,
                      const SizedBox(height: 12),
                      categoryFilter,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: statusFilter),
                    const SizedBox(width: 12),
                    Expanded(child: categoryFilter),
                  ],
                );
              },
            ),
          ],
        ),
        if (state.filters.isActive) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                searchController.clear();
                context.read<InstructorCandidatesCubit>().clearFilters();
              },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Ocisti filtere'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return AppDropdownFormField<String>(
      initialValue: value,

      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.filter_alt_outlined),
      ),
      items: [
        const AppDropdownOption(value: null, label: 'Svi statusi'),
        ..._candidateStatuses.map(
          (status) =>
              AppDropdownOption(value: status, label: _statusLabel(status)),
        ),
      ],
      onChanged: (value) =>
          context.read<InstructorCandidatesCubit>().filterStatus(value),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return AppDropdownFormField<String>(
      initialValue: value,

      decoration: const InputDecoration(
        labelText: 'Kategorija',
        prefixIcon: Icon(Icons.directions_car_outlined),
      ),
      items: [
        const AppDropdownOption(value: null, label: 'Sve kategorije'),
        ..._categoryCodes.map(
          (code) => AppDropdownOption(value: code, label: code),
        ),
      ],
      onChanged: (value) =>
          context.read<InstructorCandidatesCubit>().filterCategory(value),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});
  final InstructorCandidate candidate;
  @override
  Widget build(BuildContext context) => AppListItem(
    leading: CircleAvatar(child: Text(_initials(candidate))),
    title: candidate.fullName,
    subtitle:
        '${candidate.categoryCode} kategorija · ${candidate.completedDrivingHours} sati odrađeno · ${_statusLabel(candidate.status)}',
    onTap: () async {
      await context.push('/candidates/${candidate.id}');
      if (context.mounted) context.read<InstructorCandidatesCubit>().load();
    },
  );
}

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates({required this.hasActiveFilter});
  final bool hasActiveFilter;
  @override
  Widget build(BuildContext context) => AppEmptyState(
    title: 'Nema kandidata',
    message: hasActiveFilter
        ? 'Promijeni filtere ili pretragu.'
        : 'Još nema dodijeljenih kandidata.',
  );
}

String _initials(InstructorCandidate candidate) {
  final first = candidate.firstName.trim().isEmpty
      ? ''
      : candidate.firstName.trim()[0];
  final last = candidate.lastName.trim().isEmpty
      ? ''
      : candidate.lastName.trim()[0];
  final initials = '$first$last'.toUpperCase();
  return initials.isEmpty ? '?' : initials;
}
