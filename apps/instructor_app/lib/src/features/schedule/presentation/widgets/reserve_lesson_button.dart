import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../candidates/domain/usecases/list_instructor_candidates.dart';
import '../../domain/usecases/reserve_instructor_lesson.dart';
import '../cubit/reservation_cubit.dart';
import 'reservation_dialog.dart';

final class ReserveLessonButton extends StatelessWidget {
  const ReserveLessonButton({
    required this.onSaved,
    this.candidateId,
    this.date,
    super.key,
  });
  final VoidCallback onSaved;
  final String? candidateId;
  final DateTime? date;
  Future<void> _reserve(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final membership = auth.state.instructorMembership;
    final token = auth.state.accessToken;
    if (membership == null || token == null) return;
    final cubit = ReservationCubit(
      listCandidates: getIt<ListInstructorCandidates>(),
      reserveLesson: getIt<ReserveInstructorLesson>(),
      schoolId: membership.schoolId,
      accessToken: token,
    )..load();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ReservationDialog(
          initialDate: date ?? DateTime.now(),
          candidateId: candidateId,
        ),
      ),
    );
    final expired =
        (cubit.state.saveFailure ?? cubit.state.loadFailure)?.statusCode == 401;
    await cubit.close();
    if (expired) {
      await auth.logout();
      return;
    }
    if (saved == true && context.mounted) {
      showAppSnackBar(context, 'Termin je rezerviran.');
      onSaved();
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => _reserve(context),
    icon: const Icon(Icons.add),
    label: Text(candidateId == null ? 'Rezerviraj termin' : 'Dogovori vožnju'),
  );
}
