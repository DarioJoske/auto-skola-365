import '../../../progress/presentation/widgets/driving_hours_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../instructors/domain/entities/instructor.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/create_candidate.dart';
import '../../domain/entities/update_candidate.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';

import 'candidate_presentation.dart';

final class CandidateDialog extends StatefulWidget {
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
                      items: candidateStatuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(candidateStatusLabel(status)),
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
                      items: categoryCodes
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
