import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/candidates_cubit.dart';
import '../cubit/candidates_state.dart';
import '../widgets/candidate_form.dart';

final class CandidateEnrollmentPage extends StatelessWidget {
  const CandidateEnrollmentPage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upis kandidata',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: () => context.go('/candidates'),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text('Kandidati / Novi upis'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<CandidatesCubit, CandidatesState>(
          builder: (context, state) => Column(
            children: [
              if (state.status == CandidatesStatus.loading)
                const LinearProgressIndicator(),
              if (state.status == CandidatesStatus.failure)
                AppInlineError(
                  message: state.errorMessage ?? 'Učitavanje nije uspjelo.',
                  onRetry: () => context.read<CandidatesCubit>().load(),
                ),
            ],
          ),
        ),
        CandidateForm(
          onSaved: (candidate) => context.go('/candidates/${candidate.id}'),
          onCancel: () => context.go('/candidates'),
        ),
      ],
    ),
  );
}
