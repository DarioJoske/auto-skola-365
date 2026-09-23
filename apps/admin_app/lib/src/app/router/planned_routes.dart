import 'package:go_router/go_router.dart';
import '../../features/planned/presentation/pages/planned_page.dart';

const plannedScreens = [
  (
    path: '/exams',
    title: 'Ispiti',
    description: 'Planiranje ispita i rezultati bit će dostupni ovdje.',
  ),
  (
    path: '/fleet',
    title: 'Vozni park',
    description: 'Pregled vozila i održavanja bit će dostupan ovdje.',
  ),
  (
    path: '/finances',
    title: 'Financije',
    description: 'Pregled zaduženja i uplata bit će dostupan ovdje.',
  ),
  (
    path: '/documents',
    title: 'Dokumenti',
    description: 'Upravljanje dokumentima škole bit će dostupno ovdje.',
  ),
  (
    path: '/messages',
    title: 'Poruke',
    description:
        'Razgovori s kandidatima i instruktorima bit će dostupni ovdje.',
  ),
];

List<GoRoute> plannedRoutes() => [
  for (final screen in plannedScreens)
    GoRoute(
      path: screen.path,
      builder: (_, state) => PlannedPage(
        key: state.pageKey,
        title: screen.title,
        description: screen.description,
      ),
    ),
];
