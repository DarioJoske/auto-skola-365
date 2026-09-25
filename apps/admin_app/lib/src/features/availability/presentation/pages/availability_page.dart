import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/usecases/manage_availability.dart';
import '../cubit/availability_cubit.dart';
import 'availability_view.dart';

final class AvailabilityPage extends StatelessWidget {
  const AvailabilityPage({this.instructorId = 'me', super.key});
  final String instructorId;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final membership = auth.user?.primaryMembership;
    if (membership == null || auth.accessToken == null) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      key: ValueKey('${auth.accessToken}:$instructorId'),
      create: (_) => AvailabilityCubit(
        getIt<ManageAvailability>(),
        membership.schoolId,
        auth.accessToken!,
        instructorId,
      )..load(),
      child: const AvailabilityView(),
    );
  }
}
