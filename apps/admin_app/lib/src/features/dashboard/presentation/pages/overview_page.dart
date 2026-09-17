import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/usecases/load_school_overview.dart';
import '../cubit/school_overview_cubit.dart';
import 'overview_view.dart';

final class OverviewPage extends StatelessWidget {
  const OverviewPage({required this.loadOverview, super.key});
  final LoadSchoolOverview loadOverview;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    return BlocProvider(
      key: ValueKey(
        '${auth.user!.primaryMembership!.schoolId}:${auth.accessToken}',
      ),
      create: (_) => SchoolOverviewCubit(
        loadOverview: loadOverview,
        schoolId: auth.user!.primaryMembership!.schoolId,
        accessToken: auth.accessToken!,
      )..load(),
      child: const OverviewView(),
    );
  }
}
