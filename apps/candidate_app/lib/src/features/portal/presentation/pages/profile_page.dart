import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/portal_content.dart';
import '../widgets/profile_details_card.dart';

final class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => PortalContent(
    builder: (context, data) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Moj profil', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        ProfileDetailsCard(
          data: data,
          email: context.read<AuthCubit>().state.user?.email ?? '',
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Odjavi se'),
          ),
        ),
      ],
    ),
  );
}
