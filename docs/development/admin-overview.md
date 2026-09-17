# Admin pregled škole i instruktora — task #6

Implementacija A01/A07 koristi postojeći Flutter design system i stvarne podatke
škole iz backenda. Figma je vizualni izvor:
[A01](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=29-14),
[A07](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=34-1724).
Vozila, financije, izvoz i pretpostavljeni statusi dostupnosti iz primjera dizajna
nisu dio implementacije.

## API i ovlasti

- `GET /api/schools/{schoolId}/overview`
- `GET /api/schools/{schoolId}/instructors/overview?query=Ivan&active=true`

Oba endpointa zahtijevaju prijavljenog korisnika i aktivno članstvo s ovlastima
`candidates.manage`, `instructors.manage` i `lessons.manage` u traženoj školi.
Svaki repozitorijski upit ograničen je školom. Nedostajuća ovlast ili članstvo
daje strukturirani 403, neautentificirani poziv 401. Sažeti DTO-ovi ne izlažu
interne napomene kandidata ili termina.

`query` na pregledu instruktora pretražuje puno ime i e-mail, bez razlikovanja
velikih i malih slova; `active` je opcionalni status profila. Kategorije, kandidati
i opterećenje dolaze iz pohranjenih podataka. Pretraga kandidata na postojećem
endpointu (`q`) sada podržava i puno ime, potrebno za poveznice iz pregleda.

## Definicije pokazatelja

| Pokazatelj | Značenje |
| --- | --- |
| Aktivni kandidati | Trenutni status ENROLLED, IN_THEORY, PASSED_THEORY, IN_DRIVING, READY_FOR_EXAM ili EXAM_SCHEDULED. LEAD/PASSED/DROPPED/ARCHIVED nisu uključeni. |
| Bez instruktora | Aktivni kandidati bez dodijeljenog instruktora. Poveznica otvara postojeći popis svih kandidata bez instruktora. |
| Termini danas | Početak termina u lokalnom danu `[00:00, sljedeći dan 00:00)`, svi statusi uključujući otkazane. Potvrđeni i završeni prikazani su zasebno. |
| Otvoreni zahtjevi | Svi REQUESTED termini škole, uključujući prošle i buduće datume. |
| Čeka završetak | CONFIRMED termini čiji je `endAt <= generatedAt`; nije automatska potvrda da je vožnja održana. Završavanje ostaje u postojećem instruktorovu toku. |
| Opterećenje instruktora | Zbroj stvarnog trajanja u minutama i broj CONFIRMED termina koji počinju u tekućem tjednu, ponedjeljak 00:00 do sljedećeg ponedjeljka 00:00. REQUESTED/COMPLETED/CANCELLED/NO_SHOW ne ulaze. |
| Dodijeljeni kandidati | Svi trenutačno dodijeljeni kandidati, sa statusom i kategorijom; uključuje završene/arhivirane ako dodjela još postoji. |
| Aktivan instruktor | Pohranjeni `InstructorProfile.active`; ne označava slobodan termin ni slobodan kapacitet. |

Dan i tjedan agregiraju se u `Europe/Zagreb`, navedenom i u odgovoru i u sučelju.
Škola trenutno nema konfigurabilnu vremensku zonu. Granice se računaju lokalnim
ponoćima, uz ljetno/zimsko računanje vremena. Vremena današnjih termina prikazuju
poslužiteljev offset, ne zonu preglednika. Postojeći kalendar zadržava svoju
lokalnu vremensku zonu uređaja.

Zahtjevi i potvrđeni termini koji čekaju završetak prikazuju po 5 najstarijih
stavki uz ukupan broj. Današnji popis prikazuje sve današnje termine. Korisnik
može otvoriti termin, kandidata ili instruktora te ručno osvježiti pregled.

## Flutter organizacija i rute

- `/`: dashboard feature s vlastitim repozitorijem, use caseom i `SchoolOverviewCubit`.
- `/instructors`: operativni pregled s `InstructorOverviewCubit`, pretragom,
  tablicom, dijalogom dodijeljenih kandidata i poveznicom na potvrđeni raspored.
- `/instructors/manage`: postojeće kreiranje i uređivanje instruktora.
- `/candidates?query=...&instructorId=...` ili `withoutInstructor=true`: inicijalni
  filteri popisa i kontrola pretrage.
- `/lessons?date=...&instructorId=...&candidateId=...&status=CONFIRMED`: inicijalni
  datum i filteri kalendara. Kandidatski filter je vidljiv i može se ukloniti.

Novi Cubiti čuvaju prethodne podatke tijekom osvježavanja i oporavljive greške,
propuštaju strukturirani `Failure`, odbacuju zastarjele odgovore i rezultate nakon
zatvaranja. Pogreške učitavanja imaju inline retry; 401 prikazuje poruku isteka
sesije i odjavljuje korisnika. Kalendar također odbacuje zastarjele odgovore pri
promjeni raspona. Neaktivni instruktori ostaju vidljivi u povijesnom rasporedu;
forma novog termina nudi aktivne instruktore.

Svaki page/public widget u izmijenjenim ekranima ima svoju datoteku. Složene
cjeline novih prikaza ostaju privatni widgeti unutar datoteke. Nema novih
ovisnosti, migracija ni promjene trajanja vožnje (60 min ostaje postojeći ugovor).

## Provjere

```bash
cd apps/admin_app
dart format lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub

cd ../../backend
mvn test
mvn -DskipTests package
```

Testovi obuhvaćaju izolaciju škole, svaku potrebnu ovlast, neaktivno članstvo,
statusne agregacije, granice dana/tjedna, promjenu sata, prazne rezultate,
strukturirane greške, stale-response zaštitu, osvježavanje/retry, 401 listener,
pretragu i navigaciju kandidata te širine 390/1024/1440 i tekst 1×/2×.

Za sintetičke slike stvarnih widgeta unutar navigacijskog okvira:

```bash
OVERVIEW_SCREENSHOTS=/tmp/admin-overview flutter test --no-pub test/overview_visual_test.dart
```

Sintetičke vrijednosti žive samo u testovima. Nije izvršena provjera povezanog
toka s produkcijskom bazom.
