import 'package:auto_skola_design_system/design_system.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../instructors/domain/entities/instructor.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/create_candidate.dart';
import '../../domain/entities/update_candidate.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';

import '../pages/candidate_presentation.dart';

final class CandidateForm extends StatefulWidget {
  const CandidateForm({
    this.candidate,
    required this.onSaved,
    required this.onCancel,
    this.compact = false,
    super.key,
  });

  final ValueChanged<Candidate> onSaved;
  final VoidCallback onCancel;
  final bool compact;

  final Candidate? candidate;

  @override
  State<CandidateForm> createState() => _CandidateFormState();
}

class _CandidateFormState extends State<CandidateForm> {
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
    _status = editableCandidateStatus(candidate.status);
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
    if (candidate == null) {
      await cubit.create(
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
      );
    } else {
      await cubit.update(
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
    return assignedInstructorId;
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CandidatesCubit, CandidatesState>(
    listenWhen: (previous, current) =>
        previous.saveEventId != current.saveEventId ||
        previous.errorEventId != current.errorEventId,
    listener: (context, state) {
      if (state.errorMessage != null) {
        if (state.errorStatusCode == 401) {
          showSessionExpired(context);
          context.read<AuthCubit>().logout();
        } else {
          showAppSnackBar(context, state.errorMessage!);
        }
      } else if (state.savedCandidate != null) {
        widget.onSaved(state.savedCandidate!);
      }
    },
    builder: (context, state) => Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final personal = _FormSection(
                title: 'Osobni podaci',
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Ime'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Prezime'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Kontaktni e-mail',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return _loginPasswordController.text.isNotEmpty &&
                                !(widget.candidate?.hasLogin ?? false)
                            ? 'Za aktivaciju pristupa unesite e-mail.'
                            : null;
                      }
                      return RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(email)
                          ? null
                          : 'Unesite ispravan e-mail.';
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: _oibController,
                    decoration: const InputDecoration(labelText: 'OIB'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Interna napomena',
                    ),
                    maxLines: 3,
                  ),
                ],
              );
              final enrollment = _FormSection(
                title: 'Podaci upisa',
                children: [
                  AppDropdownFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: candidateStatuses
                        .map(
                          (value) => AppDropdownOption(
                            value: value,
                            label: candidateStatusLabel(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  AppDropdownFormField<String>(
                    initialValue: _categoryCode,
                    decoration: const InputDecoration(labelText: 'Kategorija'),
                    items: categoryCodes
                        .map(
                          (value) =>
                              AppDropdownOption(value: value, label: value),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != _categoryCode) {
                        setState(() {
                          _categoryCode = value;
                          _hoursController.text = value == 'B' ? '35' : '';
                        });
                      }
                    },
                  ),
                  AppDropdownFormField<String>(
                    initialValue: _safeInstructorValue(state.instructors),
                    decoration: const InputDecoration(
                      labelText: 'Dodijeljeni instruktor',
                    ),
                    items: [
                      const AppDropdownOption(
                        value: null,
                        label: 'Bez instruktora',
                      ),
                      if (_assignedInstructorId != null &&
                          !state.instructors.any(
                            (i) => i.id == _assignedInstructorId,
                          ))
                        AppDropdownOption(
                          value: _assignedInstructorId,
                          label:
                              widget.candidate?.assignedInstructorName ??
                              'Trenutačno dodijeljeni instruktor',
                        ),
                      ...state.instructors.map(
                        (i) =>
                            AppDropdownOption(value: i.id, label: i.fullName),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _assignedInstructorId = value),
                  ),
                  TextFormField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potreban broj sati vožnje',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _categoryCode == 'B' ||
                                (_categoryCode ==
                                        widget.candidate?.categoryCode &&
                                    widget.candidate?.requiredDrivingHours !=
                                        null)
                            ? 'Unesite potreban broj sati.'
                            : null;
                      }
                      final hours = int.tryParse(value.trim());
                      return hours == null || hours <= 0 || hours > 2147483647
                          ? 'Unesite pozitivan cijeli broj.'
                          : null;
                    },
                  ),
                  if (widget.candidate?.hasLogin ?? false) ...[
                    Text(
                      'Email za prijavu: ${widget.candidate!.loginEmail ?? ""}',
                    ),
                    const Text(
                      'Promjena kontaktnog e-maila ne mijenja e-mail za prijavu.',
                    ),
                  ],
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
                          ? 'Prazno polje čuva postojeću lozinku.'
                          : 'Za novi pristup unesite kontaktni e-mail i početnu lozinku.',
                      helperMaxLines: 3,
                    ),
                    validator: (value) =>
                        value != null &&
                            value.isNotEmpty &&
                            (value.length < 8 || value.length > 72)
                        ? 'Lozinka mora imati od 8 do 72 znaka.'
                        : null,
                  ),
                  const Text(
                    'Pristup se aktivira lozinkom. Pozivnice e-mailom još nisu dostupne.',
                  ),
                ],
              );
              return AbsorbPointer(
                absorbing: state.isSubmitting,
                child: constraints.maxWidth >= 800 && !widget.compact
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: personal),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: enrollment),
                        ],
                      )
                    : Column(
                        children: [
                          personal,
                          const SizedBox(height: AppSpacing.lg),
                          enrollment,
                        ],
                      ),
              );
            },
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: state.isSubmitting ? null : widget.onCancel,
                child: const Text('Odustani'),
              ),
              FilledButton(
                onPressed:
                    state.isSubmitting ||
                        state.status == CandidatesStatus.loading
                    ? null
                    : _submit,
                child: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Spremi'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
}

final class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => AppCard(
    showBorder: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        for (final child in children) ...[
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ],
    ),
  );
}
