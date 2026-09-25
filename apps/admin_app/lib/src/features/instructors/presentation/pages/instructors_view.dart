import '../../../availability/presentation/pages/availability_page.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/instructor_filters.dart';
import '../../domain/entities/save_instructor.dart';
import '../cubit/instructors_cubit.dart';
import '../cubit/instructors_state.dart';

const _categoryCodes = ['A', 'B', 'C', 'D', 'CE'];

const _weekDays = {
  1: 'Ponedjeljak',
  2: 'Utorak',
  3: 'Srijeda',
  4: 'Cetvrtak',
  5: 'Petak',
  6: 'Subota',
  7: 'Nedjelja',
};

final class InstructorsView extends StatefulWidget {
  const InstructorsView({super.key});

  @override
  State<InstructorsView> createState() => _InstructorsViewState();
}

class _InstructorsViewState extends State<InstructorsView> {
  bool? _active;
  String? _categoryCode;

  Future<void> _openCreateDialog(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<InstructorsCubit>(),
        child: const _InstructorDialog(),
      ),
    );

    if (created == true && context.mounted) {
      await context.read<InstructorsCubit>().load();
    }
  }

  Future<void> _openEditDialog(
    BuildContext context,
    Instructor instructor,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<InstructorsCubit>(),
        child: _InstructorDialog(instructor: instructor),
      ),
    );

    if (updated == true && context.mounted) {
      await context.read<InstructorsCubit>().load();
    }
  }

  Future<void> _applyFilters(BuildContext context) async {
    await context.read<InstructorsCubit>().applyFilters(
      InstructorFilters(active: _active, categoryCode: _categoryCode),
    );
  }

  Future<void> _clearFilters(BuildContext context) async {
    setState(() {
      _active = null;
      _categoryCode = null;
    });
    await context.read<InstructorsCubit>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InstructorsCubit, InstructorsState>(
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
      child: BlocBuilder<InstructorsCubit, InstructorsState>(
        builder: (context, state) {
          final isLoading =
              state.status == InstructorsStatus.loading ||
              state.status == InstructorsStatus.initial;
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
                            'Instruktori',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openCreateDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Novi instruktor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InstructorFiltersBar(
                      active: _active,
                      categoryCode: _categoryCode,
                      onActiveChanged: (value) =>
                          setState(() => _active = value),
                      onCategoryChanged: (value) =>
                          setState(() => _categoryCode = value),
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
                    isRefreshing: state.instructors.isNotEmpty,
                  ),
                ),
              if (state.status == InstructorsStatus.failure)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppInlineError(
                      message: state.errorMessage ?? 'Pokušaj ponovno.',
                      onRetry: () => context.read<InstructorsCubit>().load(),
                    ),
                  ),
                ),
              if (state.instructors.isEmpty &&
                  !isLoading &&
                  state.status != InstructorsStatus.failure)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    title: state.filters.isActive
                        ? 'Nema rezultata'
                        : 'Nema instruktora',
                    message: state.filters.isActive
                        ? 'Promijeni filtere.'
                        : 'Dodaj prvog instruktora za ovu auto skolu.',
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
                            : 'Dodaj instruktora',
                      ),
                    ),
                  ),
                ),
              SliverList.separated(
                key: const ValueKey('results'),
                itemCount: state.instructors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _InstructorRow(
                  instructor: state.instructors[index],
                  onEdit: () =>
                      _openEditDialog(context, state.instructors[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _InstructorFiltersBar extends StatelessWidget {
  const _InstructorFiltersBar({
    required this.active,
    required this.categoryCode,
    required this.onActiveChanged,
    required this.onCategoryChanged,
    required this.onApply,
    required this.onClear,
  });

  final bool? active;
  final String? categoryCode;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<String?> onCategoryChanged;
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
          width: 190,
          child: AppDropdownFormField<bool>(
            initialValue: active,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              AppDropdownOption(value: null, label: 'Svi'),
              AppDropdownOption(value: true, label: 'Aktivni'),
              AppDropdownOption(value: false, label: 'Neaktivni'),
            ],
            onChanged: onActiveChanged,
          ),
        ),
        SizedBox(
          width: 160,
          child: AppDropdownFormField<String>(
            initialValue: categoryCode,
            decoration: const InputDecoration(labelText: 'Kategorija'),
            items: [
              const AppDropdownOption(value: null, label: 'Sve'),
              ..._categoryCodes.map(
                (code) => AppDropdownOption(value: code, label: code),
              ),
            ],
            onChanged: onCategoryChanged,
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
}

final class _InstructorRow extends StatelessWidget {
  const _InstructorRow({required this.instructor, required this.onEdit});

  final Instructor instructor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final availability = instructor.availabilityRules.isEmpty
        ? 'Nema dostupnosti'
        : instructor.availabilityRules
              .map(
                (rule) =>
                    '${_weekDays[rule.dayOfWeek]} ${_shortTime(rule.startTime)}-${_shortTime(rule.endTime)}',
              )
              .join(', ');

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
            CircleAvatar(child: Text(instructor.firstName.characters.first)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructor.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      instructor.email,
                      instructor.phone,
                      if (instructor.licenseNumber != null)
                        'Licenca ${instructor.licenseNumber}',
                    ].whereType<String>().join(' · '),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    availability,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 6,
              children: instructor.categoryCodes
                  .map((code) => Chip(label: Text(code)))
                  .toList(),
            ),
            const SizedBox(width: 8),
            Chip(label: Text(instructor.active ? 'Aktivan' : 'Neaktivan')),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Dostupnost, pauze i odsutnost',
              icon: const Icon(Icons.event_available),
              onPressed: () async {
                final cubit = context.read<InstructorsCubit>();
                await showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    child: SizedBox(
                      width: 720,
                      height: 720,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: CloseButton(),
                          ),
                          Expanded(
                            child: AvailabilityPage(
                              instructorId: instructor.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (!cubit.isClosed) await cubit.load();
              },
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              tooltip: 'Uredi instruktora',
            ),
          ],
        ),
      ),
    );
  }
}

final class _InstructorDialog extends StatefulWidget {
  const _InstructorDialog({this.instructor});

  final Instructor? instructor;

  @override
  State<_InstructorDialog> createState() => _InstructorDialogState();
}

class _InstructorDialogState extends State<_InstructorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _active = true;
  final Set<String> _selectedCategories = {'B'};
  final List<_AvailabilityDraft> _availabilityRules = [
    _AvailabilityDraft(
      dayOfWeek: 1,
      startTime: '08:00:00',
      endTime: '16:00:00',
    ),
  ];

  bool get _isEditing => widget.instructor != null;

  @override
  void initState() {
    super.initState();

    final instructor = widget.instructor;
    if (instructor == null) {
      return;
    }

    _firstNameController.text = instructor.firstName;
    _lastNameController.text = instructor.lastName;
    _emailController.text = instructor.email;
    _phoneController.text = instructor.phone ?? '';
    _licenseController.text = instructor.licenseNumber ?? '';
    _active = instructor.active;
    _selectedCategories
      ..clear()
      ..addAll(instructor.categoryCodes);
    _availabilityRules
      ..clear()
      ..addAll(
        instructor.availabilityRules.map(
          (rule) => _AvailabilityDraft(
            dayOfWeek: rule.dayOfWeek,
            startTime: rule.startTime,
            endTime: rule.endTime,
          ),
        ),
      );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberi barem jednu kategoriju.')),
      );
      return;
    }

    final instructor = SaveInstructor(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _emptyToNull(_passwordController.text),
      phone: _emptyToNull(_phoneController.text),
      licenseNumber: _emptyToNull(_licenseController.text),
      active: _active,
      categoryCodes: _selectedCategories.toList()..sort(),
      availabilityRules: _availabilityRules
          .map(
            (rule) => InstructorAvailabilityRule(
              dayOfWeek: rule.dayOfWeek,
              startTime: rule.startTime,
              endTime: rule.endTime,
            ),
          )
          .toList(),
    );

    final cubit = context.read<InstructorsCubit>();
    final saved = widget.instructor == null
        ? await cubit.create(instructor)
        : await cubit.update(widget.instructor!.id, instructor);

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstructorsCubit, InstructorsState>(
      builder: (context, state) {
        return AlertDialog(
          title: Text(_isEditing ? 'Uredi instruktora' : 'Novi instruktor'),
          content: SizedBox(
            width: 620,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      enabled: !_isEditing,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: _isEditing
                            ? 'Nova lozinka'
                            : 'Privremena lozinka',
                        helperText: _isEditing
                            ? 'Ostavi prazno ako ne mijenjas lozinku.'
                            : 'Instruktor koristi ovu lozinku za prvu prijavu.',
                      ),
                      obscureText: true,
                      validator: _passwordValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(labelText: 'Licenca'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _active,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktivan'),
                      onChanged: (value) => setState(() => _active = value),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kategorije',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _categoryCodes
                          .map(
                            (code) => FilterChip(
                              label: Text(code),
                              selected: _selectedCategories.contains(code),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(code);
                                  } else {
                                    _selectedCategories.remove(code);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dostupnost',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _availabilityRules.add(
                                _AvailabilityDraft(
                                  dayOfWeek: 1,
                                  startTime: '08:00:00',
                                  endTime: '16:00:00',
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Dodaj termin'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._availabilityRules.indexed.map(
                      (entry) => _AvailabilityRow(
                        key: ValueKey(entry.$1),
                        rule: entry.$2,
                        onChanged: () => setState(() {}),
                        onRemove: () {
                          setState(() {
                            _availabilityRules.removeAt(entry.$1);
                          });
                        },
                      ),
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

  String? _passwordValidator(String? value) {
    final password = value?.trim() ?? '';
    if (!_isEditing && password.isEmpty) {
      return 'Unesi privremenu lozinku.';
    }
    if (password.isNotEmpty && password.length < 8) {
      return 'Lozinka mora imati najmanje 8 znakova.';
    }
    return null;
  }
}

class _AvailabilityDraft {
  _AvailabilityDraft({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  int dayOfWeek;
  String startTime;
  String endTime;
}

final class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.rule,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _AvailabilityDraft rule;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: AppDropdownFormField<int>(
              initialValue: rule.dayOfWeek,
              decoration: const InputDecoration(labelText: 'Dan'),
              items: _weekDays.entries
                  .map(
                    (entry) =>
                        AppDropdownOption(value: entry.key, label: entry.value),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  rule.dayOfWeek = value;
                  onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: TextFormField(
              initialValue: _shortTime(rule.startTime),
              decoration: const InputDecoration(labelText: 'Od'),
              validator: _timeValidator,
              onChanged: (value) {
                rule.startTime = _normalizeTime(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: TextFormField(
              initialValue: _shortTime(rule.endTime),
              decoration: const InputDecoration(labelText: 'Do'),
              validator: _timeValidator,
              onChanged: (value) {
                rule.endTime = _normalizeTime(value);
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Ukloni termin',
          ),
        ],
      ),
    );
  }
}

String _shortTime(String value) {
  return value.length >= 5 ? value.substring(0, 5) : value;
}

String _normalizeTime(String value) {
  final trimmed = value.trim();
  if (trimmed.length == 5) {
    return '$trimmed:00';
  }
  return trimmed;
}

String? _timeValidator(String? value) {
  final normalized = _normalizeTime(value ?? '');
  final valid = RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(normalized);
  if (!valid) {
    return 'Koristi HH:mm.';
  }

  final hour = int.tryParse(normalized.substring(0, 2));
  final minute = int.tryParse(normalized.substring(3, 5));
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return 'Neispravno vrijeme.';
  }

  return null;
}
