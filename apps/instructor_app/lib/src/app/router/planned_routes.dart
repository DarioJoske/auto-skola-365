import 'package:go_router/go_router.dart';
import '../../features/planned/presentation/pages/planned_page.dart';

const plannedScreens = [
  (
    path: '/home',
    title: 'Početna',
    description:
        'Dnevni pregled instruktora je u pripremi. Termine možete otvoriti u rasporedu.',
  ),
  (
    path: '/candidates/:candidateId',
    title: 'Profil kandidata',
    description:
        'Detaljni profil kandidata je u pripremi. Evidencija sati dostupna je kroz popis kandidata.',
  ),
  (
    path: '/lessons/:lessonId/request',
    title: 'Zahtjev termina',
    description:
        'Zaseban prikaz zahtjeva je u pripremi. Potvrda i otkazivanje dostupni su u detalju termina.',
  ),
  (
    path: '/lessons/:lessonId/complete',
    title: 'Završi sat',
    description:
        'Zaseban obrazac završavanja je u pripremi. Sat već možete završiti u detalju termina.',
  ),
  (
    path: '/lessons/:lessonId/completed',
    title: 'Sat je evidentiran',
    description:
        'Ovo je predviđeno mjesto za potvrdu završetka. Otvaranje ove stranice ne evidentira sat.',
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
