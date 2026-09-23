# Admin kandidati, profil i upis — task #8

Implementacija 2026-09-23, lokalne izmjene na grani
`codex/admin-candidates-profile`, polazišni HEAD `4a24324`.

## Ekrani i ponašanje

- `/candidates` (A04): dosljedni stupci imena, kategorije, instruktora,
  backend-izračunatih sati i stvarnog statusa kandidata. Pretraga i postojeći
  filtri koriste isti API. Rezultati imaju lokalnu paginaciju po 10 redaka;
  API i dalje vraća cijeli filtrirani popis. Na uskom prikazu tablica se pomiče
  vodoravno. Klik na redak otvara profil.
- `/candidates/:candidateId` (A05): izravno učitavanje kandidata iz postojeće
  školski ograničene rute, kontaktni podaci, odvojeni prijavni e-mail, status,
  interna napomena i odrađeni/ciljni sati. `37 / 35` ostaje `37 / 35`; samo
  vizualna traka staje na 100%. Nepostavljen cilj nema izmišljeni nazivnik.
- Evidencija vožnji koristi postojeći endpoint termina, filtriran kandidatom
  i odabranim kalendarskim mjesecom. Početno je odabran aktualni mjesec;
  strelice omogućuju pregled ranijih i kasnijih mjeseci. Prikazuju se vožnje
  svih kategorija i statusa, stvarni instruktor, napomena i bilješka završavanja.
  Fond sati zaseban je backend zbroj dovršenih vožnji aktualne kategorije kroz
  sva razdoblja. Mjesečni filtar ne mijenja fond.
- Uređivanje profila koristi postojeći update API. Nakon uspješnog spremanja
  profil i podaci za uređivanje ponovno se učitavaju. Akcija „Dogovori vožnju”
  otvara postojeći obrazac s kandidatom i trenutačno dodijeljenim aktivnim
  instruktorom, kada su valjani u postojećim opcijama.
- `/candidates/new` (A06): stvarni ekran upisa s odjeljcima osobnih podataka
  i upisa. Koristi isti obrazac kao uređivanje i postojeći create API.
  Nakon spremanja otvara profil kreiranog kandidata.

## Pristup i nedostupni moduli

Kontaktni e-mail može se mijenjati bez promjene prijavnog e-maila povezanog
računa. Početna lozinka uz kontaktni e-mail aktivira novi pristup; prazna
lozinka čuva postojeći pristup. Postojeći tuđi račun ne preuzima se podudaranjem
adrese. Sigurnosne provjere povezivanja i promjene lozinke ostaju na backendu.
Pozivnice nisu implementirane niti se tvrdi da je e-mail poslan.

Dokumenti, uplate i poruke na profilu otvaraju jasnu poruku da modul još nije
implementiran. Nema izmišljenih uplata, dokumenata, poruka, vozila, datuma upisa,
položenih ispita ili procjene spremnosti. Datum rođenja, datum upisa, paket i
izvoz iz Figma primjera nisu dodani jer nisu dio postojećeg ugovora ovog zadatka.

## API i asinkroni tokovi

`CandidateResponse` dobiva dodatno polje `completedDrivingHours` u list/get/
create/update odgovorima. Popisi koriste jednu agregacijsku upitnu operaciju
za školu, a ne dodatni API poziv za svaki redak. Broje se samo `COMPLETED`
`DRIVING` termini iste škole, kandidata i njegove aktualne kategorije.
Nema promjene sheme ni Flyway migracije. Stari klijent može zanemariti novo polje;
novi klijent za odsutno polje prikazuje nedostupnost, ne izmišljenu nulu.

Cubiti ignoriraju zastarjele odgovore i odgovore nakon zatvaranja. Spremanje
izlaže uspjeh kroz stanje, odbija dvostruki zahtjev, a obrazac ostaje ispunjen
nakon neuspjeha. Pogreške učitavanja imaju inline ponovni pokušaj; pogreške
spremanja snackbar i poruku uz obrazac; 401 objašnjava istek sesije prije odjave.
Postojeći podaci ostaju vidljivi tijekom osvježavanja i oporavljivih pogrešaka.
Promjena mjeseca uklanja povijest prethodnog mjeseca kako ne bi bila prikazana
pod novim datumom. Profil skriva podatke nakon 401/403/404.

## Provjere

- `dart format lib` i formatiranje izmijenjenih testova.
- `flutter analyze --no-pub` iz `apps/admin_app`.
- `flutter test --no-pub` iz `apps/admin_app`: 133 testa.
- `mvn test` iz `backend`: 35 testova na postojećoj H2 testnoj konfiguraciji.
- `mvn -DskipTests package`: uspješno.
- `flutter build web --no-pub`: uspješno; ostaje postojeće upozorenje za
  `CupertinoIcons` font.
- `git diff --check` i lokalne poveznice dokumentacije: bez grešaka.
- Vizualne snimke popisa, profila i upisa na 1440 i 390 px; uski prikazi
  dodatno provjereni s povećanjem teksta 2×.

Novi testovi pokrivaju validaciju i spremanje, ponovni pokušaj uz očuvani unos,
pristup lozinkom, paginaciju, pomicanje tablice, otvaranje profila, nedostupne
module, nadilaženje cilja, školsku/kategorijsku izolaciju, konkurentne zahtjeve,
zakašnjele odgovore i zatvaranje Cubita. Postojeći testovi nastavljaju provjeravati
sigurno povezivanje računa i pravila pozitivnog cilja. Vizualne snimke koriste
sintetičke podatke. Za ponovno generiranje:

```bash
cd apps/admin_app
CANDIDATE_SCREENSHOTS=/tmp/admin-candidates flutter test test/candidates_widgets_test.dart
```

## Izvori

- [GitHub #8](https://github.com/DarioJoske/auto-skola-365/issues/8).
- Figma [A04](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=32-331),
  [A05](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=33-439),
  [A06](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=33-1682).
- [Pravila predaje dizajna](../architecture/design-handoff.md) imaju prednost
  pred ilustrativnim podacima ekrana.
