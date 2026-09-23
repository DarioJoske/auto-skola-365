import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../instructors/domain/entities/instructor.dart';
import '../../domain/entities/candidate_filters.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';

import 'candidate_presentation.dart';
import '../widgets/candidates_table.dart';

final class CandidatesView extends StatefulWidget {
  const CandidatesView({super.key});

  @override
  State<CandidatesView> createState() => _CandidatesViewState();
}

class _CandidatesViewState extends State<CandidatesView> {
  final _searchController = TextEditingController();
  String? _status;
  String? _categoryCode;
  String? _assignedInstructorId;

  @override
  void initState() {
    super.initState();
    final filters = context.read<CandidatesCubit>().state.filters;
    _searchController.text = filters.query ?? '';
    _status = filters.status;
    _categoryCode = filters.categoryCode;
    _assignedInstructorId = filters.withoutInstructor
        ? withoutInstructorFilterValue
        : filters.assignedInstructorId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters(BuildContext context) async {
    await context.read<CandidatesCubit>().applyFilters(
      CandidateFilters(
        query: _emptyToNull(_searchController.text),
        status: _status,
        categoryCode: _categoryCode,
        assignedInstructorId:
            _assignedInstructorId == withoutInstructorFilterValue
            ? null
            : _assignedInstructorId,
        withoutInstructor:
            _assignedInstructorId == withoutInstructorFilterValue,
      ),
    );
  }

  Future<void> _clearFilters(BuildContext context) async {
    _searchController.clear();
    setState(() {
      _status = null;
      _categoryCode = null;
      _assignedInstructorId = null;
    });
    await context.read<CandidatesCubit>().clearFilters();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CandidatesCubit, CandidatesState>(
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
      child: BlocBuilder<CandidatesCubit, CandidatesState>(
        builder: (context, state) {
          final isLoading =
              state.status == CandidatesStatus.loading ||
              state.status == CandidatesStatus.initial;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.md,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kandidati',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            Text(
                              '${state.candidates.length} kandidata${state.filters.isActive ? ' · filtrirani prikaz' : ' · sve kategorije'}',
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: () => context.go('/candidates/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Upiši kandidata'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _CandidateFiltersBar(
                      searchController: _searchController,
                      status: _status,
                      categoryCode: _categoryCode,
                      assignedInstructorId: _assignedInstructorId,
                      instructors: context
                          .watch<CandidatesCubit>()
                          .state
                          .instructors,
                      onStatusChanged: (value) =>
                          setState(() => _status = value),
                      onCategoryChanged: (value) =>
                          setState(() => _categoryCode = value),
                      onInstructorChanged: (value) =>
                          setState(() => _assignedInstructorId = value),
                      onApply: () => _applyFilters(context),
                      onClear: () => _clearFilters(context),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (isLoading)
                SliverToBoxAdapter(
                  child: AppLoadingState(
                    isRefreshing: state.candidates.isNotEmpty,
                  ),
                ),
              if (state.status == CandidatesStatus.failure)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppInlineError(
                      message: state.errorMessage ?? 'Pokušaj ponovno.',
                      onRetry: () => context.read<CandidatesCubit>().load(),
                    ),
                  ),
                ),
              if (state.candidates.isEmpty &&
                  !isLoading &&
                  state.status != CandidatesStatus.failure)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    title: state.filters.isActive
                        ? 'Nema rezultata'
                        : 'Nema kandidata',
                    message: state.filters.isActive
                        ? 'Promijeni filtere ili pretragu.'
                        : 'Dodaj prvog kandidata za ovu auto skolu.',
                    action: FilledButton.icon(
                      onPressed: state.filters.isActive
                          ? () => _clearFilters(context)
                          : () => context.go('/candidates/new'),
                      icon: Icon(
                        state.filters.isActive ? Icons.clear : Icons.add,
                      ),
                      label: Text(
                        state.filters.isActive
                            ? 'Ocisti filtere'
                            : 'Dodaj kandidata',
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: CandidatesTable(candidates: state.candidates),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _CandidateFiltersBar extends StatelessWidget {
  const _CandidateFiltersBar({
    required this.searchController,
    required this.status,
    required this.categoryCode,
    required this.assignedInstructorId,
    required this.instructors,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onInstructorChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String? status;
  final String? categoryCode;
  final String? assignedInstructorId;
  final List<Instructor> instructors;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onInstructorChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: constraints.maxWidth < 320 ? constraints.maxWidth : 320,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Pretraga',
              ),
              onSubmitted: (_) => onApply(),
            ),
          ),
          SizedBox(
            width: constraints.maxWidth < 220 ? constraints.maxWidth : 220,
            child: AppDropdownFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const AppDropdownOption(value: null, label: 'Svi statusi'),
                ...candidateStatuses.map(
                  (status) => AppDropdownOption(
                    value: status,
                    label: candidateStatusLabel(status),
                  ),
                ),
              ],
              onChanged: onStatusChanged,
            ),
          ),
          SizedBox(
            width: constraints.maxWidth < 160 ? constraints.maxWidth : 160,
            child: AppDropdownFormField<String>(
              initialValue: categoryCode,
              decoration: const InputDecoration(labelText: 'Kategorija'),
              items: [
                const AppDropdownOption(value: null, label: 'Sve'),
                ...categoryCodes.map(
                  (code) => AppDropdownOption(value: code, label: code),
                ),
              ],
              onChanged: onCategoryChanged,
            ),
          ),
          SizedBox(
            width: constraints.maxWidth < 240 ? constraints.maxWidth : 240,
            child: AppDropdownFormField<String>(
              initialValue: _safeInstructorFilterValue(),
              decoration: const InputDecoration(labelText: 'Instruktor'),
              items: [
                const AppDropdownOption(value: null, label: 'Svi instruktori'),
                const AppDropdownOption(
                  value: withoutInstructorFilterValue,
                  label: 'Bez instruktora',
                ),
                ...instructors.map(
                  (instructor) => AppDropdownOption(
                    value: instructor.id,
                    label: instructor.fullName,
                  ),
                ),
              ],
              onChanged: onInstructorChanged,
            ),
          ),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Primijeni'),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Očisti'),
          ),
        ],
      ),
    );
  }

  String? _safeInstructorFilterValue() {
    final instructorId = assignedInstructorId;
    if (instructorId == null) {
      return null;
    }
    if (instructorId == withoutInstructorFilterValue) {
      return instructorId;
    }
    return instructors.any((instructor) => instructor.id == instructorId)
        ? instructorId
        : null;
  }
}
