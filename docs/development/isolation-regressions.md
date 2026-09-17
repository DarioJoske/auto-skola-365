# Regresije izolacije škole i domenskih pravila

Zadatak: [GitHub #4](https://github.com/DarioJoske/auto-skola-365/issues/4).
Datum provjere: 2026-09-17. Implementacija je lokalna, necommitana na grani
`codex/issue-4-isolation-regressions`, s baznim HEAD-om
`6310c45e64957c963d19fccbdec95b63c41d8bfb`.

## Što provjere štite

- `TenancyRegressionTest` provjerava drugu školu, strani ID pod vlastitom školom,
  tuđeg kandidata i instruktorov termin, ukinuto članstvo uz već izdani token,
  promjenu dodjele i privatnost internih bilješki u kandidatskom portalu.
- Provjere zbroja isključuju tuđeg kandidata, nezavršene termine, druge vrste
  nastave i staru kategoriju. Postojeći `AuthFlowIntegrationTest` dodatno
  provjerava prekoračenje cilja, raniji zabranjeni upis napretka i dvostruko
  završavanje s ishodom 200/409 i samo jednim odrađenim satom.
- Konkurentne rezervacije kandidata i instruktora, različiti kandidati istog
  instruktora, potvrđivanje otkazanog termina, pomicanje i promijenjena dodjela
  imaju samo jednog pobjednika. Kandidat pa instruktor zaključavaju se do
  završetka transakcije. Zaštita djeluje kroz bazu i između instanci aplikacije.
- `api_failure_test.dart` u svakoj aplikaciji provjerava stvarni Dio → ApiClient
  → ApiException → Failure tok te `Left` u stvarnoj repository implementaciji.
  Pokriveni su 400/401/403/404/409/500, nedostajuće ili neispravno tijelo i
  prekid veze. Sva podržana HTTP sredstva čuvaju status, kod, poruku i putanju.
- Widget testovi provjeravaju 403 i uklanjanje zaštićenih sati, inline grešku
  s ponovnim pokušajem, mutacijski konflikt te jasnu poruku isteka sesije.
  Kandidatski test prolazi stvarnom navigacijom nakon konflikta i 401.
- Admin obnova sesije čuva cijeli Failure i prikazuje grešku na prijavi.
  Kandidatski 401 uklanja stare snackbar poruke prije prikaza isteka sesije.

Ne uvode se novi modeli baze ni migracije; V1–V12 ostaju neizmijenjene.
Vrijedi postojeći odnos 60 minuta termina = jedan nastavni sat, bez promjene
statusa ili kriterija završavanja prema Figma primjerima.

## Lokalna provjera

Iz `backend/`:

```bash
mvn test
mvn -DskipTests package
```

Iz svake od `apps/admin_app`, `apps/instructor_app`, `apps/candidate_app`:

```bash
dart format lib
flutter analyze --no-pub
flutter test --no-pub
```

Promijenjeni Dart testovi također su formatirani. Nisu mijenjane ovisnosti.

## PostgreSQL i Flyway

Standardni `mvn test` koristi H2 i ne provjerava migracije. Sljedeći odabrani
skup izvršava se nad zasebnim privremenim PostgreSQL-om 16 s Flyway migracijama i
Hibernate provjerom sheme. Fixture prije svakog testa briše testne podatke;
URL mora pokazivati na ovu izoliranu bazu.

Iz `backend/`, uz slobodan lokalni port 55434:

```bash
docker run --detach --rm --name auto-skola-issue4-test \
  --publish 127.0.0.1:55434:5432 \
  --env POSTGRES_USER=issue4 --env POSTGRES_PASSWORD=issue4-test-only \
  --env POSTGRES_DB=issue4 postgres:16-alpine
# Nakon što pg_isready potvrdi da je baza spremna:
docker exec auto-skola-issue4-test pg_isready -U issue4 -d issue4
mvn '-Dtest=TenancyRegressionTest,AuthFlowIntegrationTest#progressCountsOnlyCompletedDrivingHoursAndRequiresAssignedAccess' \
  -Dspring.datasource.url=jdbc:postgresql://127.0.0.1:55434/issue4 \
  -Dspring.datasource.username=issue4 \
  -Dspring.datasource.password=issue4-test-only \
  -Dspring.jpa.hibernate.ddl-auto=validate -Dspring.flyway.enabled=true test
docker stop auto-skola-issue4-test
```

## Rezultati i granice

- H2: svih 25 backend testova prolazi; backend paket uspješno izrađen.
- PostgreSQL 16: 11 odabranih testova prolazi, uključujući istodobne rezervacije
  i završavanje. Svih 12 Flyway migracija primijenjeno je na praznu bazu;
  Hibernate validacija prolazi. Razvojna baza nije mijenjana.
- Flutter: admin 56, instruktor 58, kandidat 43 testa; sve tri analize bez nalaza.
- `git diff --check` prolazi.

Prije popravka novi testovi reproducirali su dvostruku rezervaciju instruktora,
konflikt ponovne potvrde i rezervacije te nestrukturirani 401. Konkurentni
HTTP zahtjevi sinkroniziraju početak i imaju ograničeno čekanje; testovi nisu
formalni dokaz za sve moguće rasporede niti test opterećenja. Ručni tok na
stvarnim Android/iOS uređajima i buildovi mobilnih aplikacija nisu izvedeni.
