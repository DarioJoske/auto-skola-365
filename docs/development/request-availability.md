# Zahtjevi termina i dostupnost — task #10

Datum: 2026-09-25. [GitHub #10](https://github.com/DarioJoske/auto-skola-365/issues/10).
Nadogradnja obuhvaća I07, I08, C04 i C05 te administraciju dostupnosti.
Korisnička odluka: kandidat mora prihvatiti ili odbiti instruktorov prijedlog
drugog vremena prije potvrđivanja vožnje.

## Tok i statusi

- C04 `/lessons/request` šalje zahtjev za budući termin, fiksnih 60 minuta,
  s neobaveznom napomenom. Backend izvodi identitet kandidata i instruktora.
- C05 `/lessons/request-sent` prikazuje potvrdu uspješnog slanja u aktualnoj
  sesiji; izravno otvaranje bez slanja prikazuje samo poveznicu na termine.
  Potvrda primitka nije potvrđena vožnja i ne obećava push obavijest.
- I07 `/lessons/:lessonId/request` prikazuje datum, vrijeme, kandidata i
  napomenu. Instruktor potvrđuje, odbija uz dijalog ili bira i šalje novo vrijeme.
- Prijedlog sprema `proposedStartAt` na isti `REQUESTED` zapis. Dok kandidat
  ne odgovori, UI prikazuje „Čeka odgovor kandidata”; confirm i admin uređivanje
  ne mogu preskočiti odgovor. Dopušteno je izričito otkazivanje.
- Kandidat prihvaća ili odbija u popisu termina. Prihvaćanje premješta isti zapis
  i postavlja `CONFIRMED`; odbijanje postavlja `CANCELLED` i uklanja prijedlog.
  Odgovor šalje očekivani `startAt`; zastarjeli ili ponovljeni odgovor daje `409`.
- Odbijanje instruktora također znači `CANCELLED`. Kandidatski zahtjev može se
  potvrditi endpointom confirm samo iz `REQUESTED`. Ostali postojeći administrativni
  prijelazi zadržani su osim zabrane uređivanja dok prijedlog čeka odgovor.
- Zahtjev i prijedlog ne dodaju sate. Samo postojeći postupak završavanja
  `CONFIRMED` → `COMPLETED` utječe na backend zbroj.

Izvorni interval zahtjeva blokira raspored dok se zahtjev ne riješi. Predloženi
interval nije dodatno rezerviran: provjerava se pri slanju i ponovno pri
prihvaćanju. U međuvremenu ga može zauzeti drugi termin ili odsutnost; kandidat
tada vidi konflikt, a zahtjev i prijedlog ostaju sačuvani.

## Dostupnost

I08 `/availability` i administrativni dijalog na popisu instruktora uređuju:

- Tjedne intervale po danima ISO 1–7, u zoni `Europe/Zagreb`. Termin mora
  cijelim trajanjem stati u jedan interval. Prazan popis zadržava kompatibilno
  ponašanje bez tjednog ograničenja; UI to izričito navodi.
- Pauze (`BREAK`) i odsutnosti (`ABSENCE`) s početkom i završetkom kao UTC
  trenutcima. UI ih unosi i prikazuje u lokalnoj zoni uređaja.

Promjena koja isključuje postojeći neotkazani termin čiji kraj još nije prošao
vraća `409`. Ni zahtjevi ni potvrđene vožnje ne brišu se i ne otkazuju automatski.
Pauze mogu trajati kraće od vožnje; dodirivanje granica nije preklapanje.
Pravila se primjenjuju i na ranije API-je kreiranja, rezervacije, izmjene i potvrde.
Administrativno uređivanje tjednih pravila u profilu također provjerava termine.

## API i migracija

Sve putanje imaju prefiks `/api/schools/{schoolId}` i zahtijevaju aktivno članstvo.

| Metoda i putanja | Tijelo / odgovor |
| --- | --- |
| `POST /lessons/{lessonId}/propose` | `{ "startAt": "2030-01-08T09:00:00Z" }` → `LessonResponse`, 200 |
| `POST /lessons/{lessonId}/reject` | Bez tijela → `LessonResponse`, 200 |
| `POST /lessons/candidate/{lessonId}/proposal-response` | `{ "startAt": "2030-01-08T09:00:00Z", "accept": true }` → 204 bez DTO-a s internim bilješkama |
| `GET/PUT /instructors/me/availability` | Instruktorova dostupnost iz prijavljenog identiteta |
| `GET/PUT /instructors/{instructorId}/availability` | Administracija uz `instructors.manage` |

PUT dostupnosti prima `rules: [{dayOfWeek, startTime, endTime}]` i
`blocks: [{startAt, endAt, kind}]`; vraća iste podatke i `timeZone`.
`LessonResponse` i ograničeni kandidatski DTO dobivaju nullable `proposedStartAt`.
Kandidatski DTO i dalje ne otkriva interne bilješke.

Instruktorove odluke zahtijevaju njegov termin i aktualnu dodjelu kandidata;
admin može odlučivati uz `lessons.manage`. Provjeravaju se škola, aktivni profil,
članstvo i kategorija. Kandidatski odgovor dodatno provjerava vlasništvo zapisa.
Odluke zaključavaju termin, kandidata pa instruktora. Dostupnost zaključava isti
redak instruktora; nakon zaključavanja čitaju se aktualna pravila i konflikti.
Time konkurentno prihvaćanje/rezervacija i promjena dostupnosti imaju jednog
pobjednika. Neuspjeh vraća strukturirani `400`, `403`, `404` ili `409`.

`V13__request_proposals_and_availability.sql` dodaje `lessons.proposed_start_at`
i tablicu `instructor_availability_blocks`. Ranije migracije nisu mijenjane.

## Provjere i granice

Izvršeno 2026-09-25:

- Dart format i analiza sve tri aplikacije; puni Flutter testovi: admin 138,
  instruktor 96, kandidat 54.
- `mvn test`: 44 testa na H2; `mvn -DskipTests package` uspješan.
- `TenancyRegressionTest`: 22 testa na izoliranom PostgreSQL-u 16, uz Flyway
  migracije V1–V13 i Hibernate validaciju sheme. Provjerene utrke potvrda/odbijanja,
  prihvaćanja/odsutnosti i dva prijedloga istog termina.
- UI provjere uspjeha, odbijanja, grešaka, ponavljanja, očuvanja unosa i teksta 2×.
  C04/C05 test koristi pravi router i podatkovni sloj s testnim Dio odgovorima.
- Vizualno pregledani I07, I08, C04 i C05 na 390 × 844. Nije izveden povezani
  test aplikacije protiv živog API-ja niti test na fizičkom uređaju.

Za opcionalne snimke postaviti `REQUEST_SCREENSHOTS=/tmp/request-screenshots`
pri pokretanju `test/request_workflow_test.dart` i instruktorova
`test/availability_test.dart`. Testovi koriste sintetičke podatke.

Figma izvori: [I07](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-1057),
[I08](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=28-397),
[C04](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=25-236),
[C05](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=25-306).
Primjenjuje se [design handoff](../architecture/design-handoff.md): trajanje,
statusi i prava pristupa dolaze iz domene, a komponente iz zajedničkog sustava dizajna.
