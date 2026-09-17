import 'package:auto_skola_design_system/design_system.dart';
import '../../../../app/app_dependencies.dart';
import '../../../progress/domain/usecases/load_progress.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../instructors/domain/entities/instructor.dart';
import '../../../instructors/domain/usecases/list_instructors.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filters.dart';
import '../../domain/entities/create_candidate.dart';
import '../../domain/entities/update_candidate.dart';
import '../../domain/usecases/create_candidate.dart';
import '../../domain/usecases/list_candidates.dart';
import '../../domain/usecases/update_candidate.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';

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

const _categoryCodes = ['A', 'B', 'C', 'D', 'CE'];
const _withoutInstructorFilterValue = '__without_instructor__';

String _editableCandidateStatus(String status) {
  return _candidateStatuses.contains(status) ? status : 'ENROLLED';
}

String _statusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Aktivan',
    'LEAD' => 'Lead',
    'ENROLLED' => 'Upisan',
    'IN_THEORY' => 'Na teoriji',
    'PASSED_THEORY' => 'Polozio teoriju',
    'IN_DRIVING' => 'Na voznji',
    'READY_FOR_EXAM' => 'Spreman za ispit',
    'EXAM_SCHEDULED' => 'Ispit zakazan',
    'PASSED' => 'Polozio',
    'DROPPED' => 'Odustao',
    'ARCHIVED' => 'Arhiviran',
    _ => status,
  };
}

class CandidatesPage extends StatelessWidget {
  const CandidatesPage({
    required this.listCandidates,
    required this.listInstructors,
    required this.createCandidate,
    required this.updateCandidate,
    super.key,
  });

  final ListCandidates listCandidates;
  final ListInstructors listInstructors;
  final CreateCandidateUseCase createCandidate;
  final UpdateCandidateUseCase updateCandidate;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final membership = authState.user!.primaryMembership!;

    return BlocProvider(
      create: (_) => CandidatesCubit(
        listCandidates: listCandidates,
        listInstructors: listInstructors,
        createCandidate: createCandidate,
        updateCandidate: updateCandidate,
        schoolId: membership.schoolId,
        accessToken: authState.accessToken!,
      )..load(),
      child: const CandidatesView(),
    );
  }
}

class CandidatesView extends StatefulWidget {
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
            _assignedInstructorId == _withoutInstructorFilterValue
            ? null
            : _assignedInstructorId,
        withoutInstructor:
            _assignedInstructorId == _withoutInstructorFilterValue,
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

class _CandidateFiltersBar extends StatelessWidget {
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
              ..._candidateStatuses.map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
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
              ..._categoryCodes.map(
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
                value: _withoutInstructorFilterValue,
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
    if (instructorId == _withoutInstructorFilterValue) {
      return instructorId;
    }
    return instructors.any((instructor) => instructor.id == instructorId)
        ? instructorId
        : null;
  }
}

class _CandidateRow extends StatelessWidget {
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
            Chip(label: Text(_statusLabel(candidate.status))),
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

class CandidateDialog extends StatefulWidget {
  const CandidateDialog({this.candidate, super.key});

  final Candidate? candidate;

  @override
  State<CandidateDialog> createState() => _CandidateDialogState();
}

class _CandidateDialogState extends State<CandidateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oibController = TextEditingController();
  final _notesController = TextEditingController();
  final _hoursController = TextEditingController(text: '35');
  final _loginPasswordController = TextEditingController();

  String _categoryCode = 'B';
  String _status = 'LEAD';
  String? _assignedInstructorId;

  bool get _isEditing => widget.candidate != null;

  @override
  void initState() {
    super.initState();

    final candidate = widget.candidate;
    if (candidate == null) {
      return;
    }

    _hoursController.text = candidate.requiredDrivingHours?.toString() ?? '';
    _firstNameController.text = candidate.firstName;
    _lastNameController.text = candidate.lastName;
    _emailController.text = candidate.email ?? '';
    _phoneController.text = candidate.phone ?? '';
    _oibController.text = candidate.oib ?? '';
    _notesController.text = candidate.notes ?? '';
    _categoryCode = candidate.categoryCode;
    _status = _editableCandidateStatus(candidate.status);
    _assignedInstructorId = candidate.assignedInstructorId;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oibController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<CandidatesCubit>();
    final candidate = widget.candidate;
    final saved = candidate == null
        ? await cubit.create(
            CreateCandidate(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emptyToNull(_emailController.text),
              phone: _emptyToNull(_phoneController.text),
              oib: _emptyToNull(_oibController.text),
              status: _status,
              categoryCode: _categoryCode,
              assignedInstructorId: _assignedInstructorId,
              notes: _emptyToNull(_notesController.text),
              requiredDrivingHours: int.tryParse(_hoursController.text.trim()),
              loginPassword: _loginPasswordController.text.isEmpty
                  ? null
                  : _loginPasswordController.text,
            ),
          )
        : await cubit.update(
            candidate.id,
            UpdateCandidate(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emptyToNull(_emailController.text),
              phone: _emptyToNull(_phoneController.text),
              oib: _emptyToNull(_oibController.text),
              status: _status,
              categoryCode: _categoryCode,
              assignedInstructorId: _assignedInstructorId,
              notes: _emptyToNull(_notesController.text),
              requiredDrivingHours: int.tryParse(_hoursController.text.trim()),
              loginPassword: _loginPasswordController.text.isEmpty
                  ? null
                  : _loginPasswordController.text,
            ),
          );

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _safeInstructorValue(List<Instructor> instructors) {
    final assignedInstructorId = _assignedInstructorId;
    if (assignedInstructorId == null) {
      return null;
    }
    final exists = instructors.any(
      (instructor) => instructor.id == assignedInstructorId,
    );
    return exists ? assignedInstructorId : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CandidatesCubit, CandidatesState>(
      builder: (context, state) {
        return AlertDialog(
          title: Text(_isEditing ? 'Uredi kandidata' : 'Novi kandidat'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isEditing) ...[
                      const DrivingHoursPanel(),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'Ime'),
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Prezime',
                            ),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _oibController,
                      decoration: const InputDecoration(labelText: 'OIB'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _candidateStatuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      initialValue: _categoryCode,
                      decoration: const InputDecoration(
                        labelText: 'Kategorija',
                      ),
                      items: _categoryCodes
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _categoryCode = value;
                            _hoursController.text = value == 'B' ? '35' : '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      isDense: false,
                      initialValue: _safeInstructorValue(state.instructors),
                      decoration: const InputDecoration(
                        labelText: 'Dodijeljeni instruktor',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Bez instruktora'),
                        ),
                        ...state.instructors.map(
                          (instructor) => DropdownMenuItem(
                            value: instructor.id,
                            child: Text(instructor.fullName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _assignedInstructorId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Potreban broj sati vožnje',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _categoryCode == 'B' ||
                                  widget.candidate?.requiredDrivingHours != null
                              ? 'Unesite potreban broj sati.'
                              : null;
                        }
                        final hours = int.tryParse(value.trim());
                        return hours == null || hours <= 0 || hours > 2147483647
                            ? 'Unesite pozitivan cijeli broj.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (widget.candidate?.hasLogin ?? false)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Kandidatski pristup je aktiviran'),
                        subtitle: Text(
                          'Email za prijavu: ${widget.candidate!.loginEmail ?? ""}',
                        ),
                      ),
                    TextFormField(
                      controller: _loginPasswordController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: (widget.candidate?.hasLogin ?? false)
                            ? 'Nova lozinka za kandidatsku aplikaciju'
                            : 'Lozinka za kandidatsku aplikaciju (neobavezno)',
                        helperText: (widget.candidate?.hasLogin ?? false)
                            ? 'Ostavite prazno ako ne mijenjate lozinku.'
                            : 'Unesite email i lozinku za aktivaciju pristupa.',
                      ),
                      validator: (value) =>
                          value != null &&
                              value.isNotEmpty &&
                              (value.length < 8 || value.length > 72)
                          ? 'Lozinka mora imati od 8 do 72 znaka.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Napomena'),
                      maxLines: 3,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: state.isSubmitting ? null : _submit,
              child: state.isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Spremi'),
            ),
          ],
        );
      },
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Obavezno polje.';
    }
    return null;
  }
}
