import 'package:go_router/go_router.dart';
import '../../features/planned/presentation/pages/planned_page.dart';

const plannedScreens = [
  (
    path: '/journey',
    title: 'Moj put',
    description:
        'Pregled koraka osposobljavanja je u pripremi. Aktualni broj sati prikazan je na početnoj stranici.',
  ),
  (
    path: '/lessons/request',
    title: 'Zatraži vožnju',
    description:
        'Samostalan ekran zahtjeva je u pripremi. Zahtjev već možete poslati kroz početnu stranicu ili termine.',
  ),
  (
    path: '/lessons/request-sent',
    title: 'Zahtjev je poslan',
    description:
        'Ovo je predviđeno mjesto za potvrdu zahtjeva. Otvaranje ove stranice ne šalje zahtjev.',
  ),
  (
    path: '/lessons/:lessonId',
    title: 'Detalj termina',
    description:
        'Detaljni prikaz termina je u pripremi. Osnovne podatke možete pronaći u popisu termina.',
  ),
  (
    path: '/exams',
    title: 'Moj ispit',
    description: 'Informacije o ispitu bit će dostupne ovdje.',
  ),
  (
    path: '/documents-payments',
    title: 'Dokumenti i uplate',
    description: 'Pregled vaših dokumenata i uplata bit će dostupan ovdje.',
  ),
  (
    path: '/messages',
    title: 'Poruke',
    description: 'Razgovori s instruktorom i školom bit će dostupni ovdje.',
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
