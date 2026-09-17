import 'package:flutter/material.dart';
import 'src/app/app_dependencies.dart';
import 'src/app/candidate_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const CandidateApp());
}
