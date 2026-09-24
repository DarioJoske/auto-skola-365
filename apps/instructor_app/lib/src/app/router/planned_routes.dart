import 'package:go_router/go_router.dart';
import '../../features/planned/presentation/pages/planned_page.dart';

const plannedScreens = [
  (
    path: '/lessons/:lessonId/request',
    title: 'Zahtjev termina',
    description:
        'Zaseban prikaz zahtjeva je u pripremi. Potvrda i otkazivanje dostupni su u detalju termina.',
  ),
  (
    path: '/availability',
    title: 'Moja dostupnost',
    description: 'Uređivanje dostupnosti instruktora bit će dostupno ovdje.',
  ),
  (
    path: '/messages',
    title: 'Poruke',
    description: 'Razgovori s kandidatima i školom bit će dostupni ovdje.',
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
