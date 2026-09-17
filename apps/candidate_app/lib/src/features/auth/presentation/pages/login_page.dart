import 'package:flutter/material.dart';
import '../widgets/login_form.dart';

final class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const LoginForm(),
          ),
        ),
      ),
    ),
  );
}
