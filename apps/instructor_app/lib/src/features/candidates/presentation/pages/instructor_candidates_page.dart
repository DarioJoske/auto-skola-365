import 'package:auto_skola_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/instructor_candidate.dart';
import '../../domain/usecases/list_instructor_candidates.dart';
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

class InstructorCandidatesPage extends StatelessWidget {
  const InstructorCandidatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final membership = authState.instructorMembership;
        final accessToken = authState.accessToken;

        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (membership == null || accessToken == null) {
          return _CandidatesAccessError(
            onLogout: () => context.read<AuthCubit>().logout(),
          );
        }

        return BlocProvider(
          create: (_) => InstructorCandidatesCubit(
            listInstructorCandidates: getIt<ListInstructorCandidates>(),
            schoolId: membership.schoolId,
            accessToken: accessToken,
          )..load(),
          child: const InstructorCandidatesView(),
        );
      },
    );
  }
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
          return RefreshIndicator(
            onRefresh: () => context.read<InstructorCandidatesCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _CandidatesHeader(
                  count: state.candidates.length,
                  isLoading: state.isLoading,
                  onRefresh: () =>
                      context.read<InstructorCandidatesCubit>().load(),
                ),
                if (state.isLoading)
                  AppLoadingState(isRefreshing: state.candidates.isNotEmpty),
                const SizedBox(height: 16),
                _CandidatesFilters(
                  searchController: _searchController,
                  state: state,
                ),
                const SizedBox(height: 12),
                if (state.status == InstructorCandidatesStatus.failure)
                  AppInlineError(
                    message:
                        state.errorMessage ?? 'Kandidate nije moguce ucitati.',
                    onRetry: () =>
                        context.read<InstructorCandidatesCubit>().load(),
                  ),
                if (state.candidates.isEmpty &&
                    !state.isLoading &&
                    state.status != InstructorCandidatesStatus.failure)
                  _EmptyCandidates(hasActiveFilter: state.filters.isActive)
                else
                  ...state.candidates.map(
                    (candidate) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CandidateCard(candidate: candidate),
                    ),
                  ),
              ],
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
            labelText: 'Pretraga',
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Text(_initials(candidate))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_statusLabel(candidate.status)} · ${candidate.categoryName}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () =>
                  context.push('/candidates/${candidate.id}/progress'),
              icon: const Icon(Icons.trending_up),
              label: const Text('Odrađeni sati'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_hasValue(candidate.phone))
                  _InfoChip(
                    icon: Icons.phone_outlined,
                    label: candidate.phone!,
                  ),
                if (_hasValue(candidate.email))
                  _InfoChip(icon: Icons.mail_outline, label: candidate.email!),
                if (_hasValue(candidate.oib))
                  _InfoChip(
                    icon: Icons.badge_outlined,
                    label: 'OIB ${candidate.oib}',
                  ),
              ],
            ),
            if (_hasValue(candidate.notes)) ...[
              const SizedBox(height: 12),
              Text(candidate.notes!, maxLines: 3),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _CandidatesAccessError extends StatelessWidget {
  const _CandidatesAccessError({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: colorScheme.onErrorContainer),
                const SizedBox(height: 12),
                Text(
                  'Korisnik nema pristup dodijeljenim kandidatima.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Odjavi se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty;
}
