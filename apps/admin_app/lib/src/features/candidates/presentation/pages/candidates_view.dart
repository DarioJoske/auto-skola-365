import 'package:auto_skola_design_system/design_system.dart';
import '../../../../app/app_dependencies.dart';
import '../../../progress/domain/usecases/load_progress.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../instructors/domain/entities/instructor.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filters.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';

import 'candidate_presentation.dart';
import 'candidate_dialog.dart';

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

  Future<void> _openCreateDialog(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CandidatesCubit>(),
        child: const CandidateDialog(),
      ),
    );

    if (created == true && context.mounted) {
      await context.read<CandidatesCubit>().load();
    }
  }

  Future<void> _openEditDialog(
    BuildContext context,
    Candidate candidate,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CandidatesCubit>(),
        child: BlocProvider(
          create: (_) => ProgressCubit(
            loadProgress: getIt<LoadProgress>(),
            schoolId: candidate.schoolId,
            accessToken: context.read<AuthCubit>().state.accessToken!,
            resource: 'candidates',
            id: candidate.id,
          )..load(),
          child: CandidateDialog(candidate: candidate),
        ),
      ),
    );

    if (updated == true && context.mounted) {
      await context.read<CandidatesCubit>().load();
    }
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kandidati',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openCreateDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Novi kandidat'),
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
                          : () => _openCreateDialog(context),
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
              SliverList.separated(
                key: const ValueKey('results'),
                itemCount: state.candidates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _CandidateRow(
                  candidate: state.candidates[index],
                  onEdit: () =>
                      _openEditDialog(context, state.candidates[index]),
                ),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
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
          width: 220,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            itemHeight: null,
            isDense: false,
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Svi statusi')),
              ...candidateStatuses.map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(candidateStatusLabel(status)),
                ),
              ),
            ],
            onChanged: onStatusChanged,
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            itemHeight: null,
            isDense: false,
            initialValue: categoryCode,
            decoration: const InputDecoration(labelText: 'Kategorija'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sve')),
              ...categoryCodes.map(
                (code) => DropdownMenuItem(value: code, child: Text(code)),
              ),
            ],
            onChanged: onCategoryChanged,
          ),
        ),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            itemHeight: null,
            isDense: false,
            initialValue: _safeInstructorFilterValue(),
            decoration: const InputDecoration(labelText: 'Instruktor'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Svi instruktori'),
              ),
              const DropdownMenuItem(
                value: withoutInstructorFilterValue,
                child: Text('Bez instruktora'),
              ),
              ...instructors.map(
                (instructor) => DropdownMenuItem(
                  value: instructor.id,
                  child: Text(instructor.fullName),
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
          label: const Text('Ocisti'),
        ),
      ],
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

final class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate, required this.onEdit});

  final Candidate candidate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Text(candidate.firstName.characters.first)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      candidate.email,
                      candidate.phone,
                      'Kategorija ${candidate.categoryCode}',
                      if (candidate.assignedInstructorName != null)
                        'Instruktor ${candidate.assignedInstructorName}',
                    ].whereType<String>().join(' · '),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Chip(label: Text(candidateStatusLabel(candidate.status))),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              tooltip: 'Uredi kandidata',
            ),
          ],
        ),
      ),
    );
  }
}
