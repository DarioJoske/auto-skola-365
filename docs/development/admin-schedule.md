# Admin raspored i preostale rute dizajna

Datum: 2026-09-18. [Zadatak #7](https://github.com/DarioJoske/auto-skola-365/issues/7).
Pregledani Figma [A02](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=30-144)
i [A03](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=31-263),
te inventar stranica Admin App, Instructor App i Candidate App.

## Raspored i obrazac

- Zadani tjedni prikaz koristi kartice s vremenom, kandidatom, instruktorom,
  kategorijom i tekstualnim statusom. Prema A02 početno se prikazuje pet stupaca
  (ponedjeljak–petak), s razmacima 16 px, karticama radiusa 12 px i naslovom 32 px.
  Gumb „Novi termin” nalazi se uz naslov, a alatna traka ispod njega. Identitet
  i odjava na desktopu su u sidebaru, bez dodatnog zaglavlja iznad sadržaja.
  Vikend se automatski prikaže kada postoji vikend termin, a može se uključiti
  i kroz „Dodatni prikazi i filtri”. Na uskim ekranima stupci se pomiču vodoravno.
  Tjedan i mjesec su izravne kontrole; dan, radni tjedan, prikaz po instruktorima
  i filtar svih pet statusa dostupni su u dodatnom izborniku.
- Filtri obuhvaćaju instruktora i svih pet statusa. Poveznice iz pregleda škole
  i dalje mogu zadati datum i kandidata. Uspješna mutacija zadržava odabrani
  raspon, filtre i pogled; osvježavanje ne uklanja postojeći sadržaj.
- Klik na karticu otvara detalj s dopuštenim radnjama. Otkazivanje traži
  potvrdu; konačni statusi ne nude uređivanje, potvrdu ni otkazivanje.
- A03 je prilagodljivi dijalog, dostupan iz rasporeda i na `/lessons/new`.
  Instruktor se bira prvi; kandidat se resetira pri promjeni instruktora.
  Popis se ponovno učitava prije otvaranja obrasca. Nema odabira vozila.
- Trajanje ostaje **60 minuta**, prema [handoffu](../architecture/design-handoff.md).
  Bilješka je interna. Backend provjerava aktualnu dodjelu, školu, kategoriju,
  aktivnost instruktora i preklapanja. Ne prikazuje se unaprijed tvrdnja da
  preklapanja nema; provjera se radi pri spremanju.
- `409` sadrži konkretan resurs (kandidat/instruktor) i zauzeti interval u
  eksplicitno označenom UTC-u, bez imena drugog kandidata. Obrazac prikazuje
  poruku i zadržava odabire, datum i bilješku za ispravak i ponovni pokušaj.
- `LessonsCubit` izlaže rezultat kroz stanje (`savedEventId`), sprečava
  dvostruko spremanje, odbacuje zastarjele odgovore i provjerava zatvaranje.
  Uspjeh spremanja zatvara dijalog neovisno o uspjehu naknadnog učitavanja;
  greška osvježavanja ostaje u rasporedu s ponovnim pokušajem.

## Mapa svih ekrana dizajna

`Placeholder` znači stranicu s oznakom **U pripremi**, bez novih poslovnih
operacija ili lažnih podataka. Odredišta su u redovitim navigacijskim trakama,
bez dodatnog gumba ili kataloga „Svi ekrani”. Sve su nove rute unutar postojećeg
autentificiranog navigacijskog okvira. Admin izbornik uključuje ispite, vozni park,
financije, dokumente i poruke. Kandidat ima **Početna / Termini / Moj put / Poruke /
Profil**, a instruktor **Danas / Raspored / Kandidati / Poruke / Profil**, prema
Figma C01/I01. Detalji i potvrde imaju rezervirane putanje, ali nisu zasebne
stavke glavne navigacije. Instruktorov Profil prikazuje postojeće podatke iz
postavki; kompatibilna ruta `/settings` ostaje dostupna.

| Admin dizajn | Ruta / ulaz | Stanje |
| --- | --- | --- |
| A01 Pregled škole | `/` | Postojeća implementacija |
| A02 Tjedni raspored | `/lessons` | Redizajn #7 |
| A03 Novi termin | `/lessons/new`, gumb u rasporedu | Obrazac #7 |
| A04 Kandidati | `/candidates` | Postojeća implementacija |
| A05 Profil kandidata | `/candidates/:candidateId` | Implementirano u [tasku #8](admin-candidates.md): profil, sati i mjesečna evidencija vožnji |
| A06 Upis kandidata | `/candidates/new` | Implementirano u [tasku #8](admin-candidates.md): samostalni upis uz aktivaciju lozinkom |
| A07 Instruktori | `/instructors` | Postojeća implementacija |
| A08 Ispiti | `/exams` | Placeholder |
| A09 Vozni park | `/fleet` | Placeholder |
| A10 Financije | `/finances` | Placeholder |
| A11 Dokumenti | `/documents` | Placeholder |
| A12 Poruke | `/messages` | Placeholder |
| A13 Postavke škole | `/settings` | Dorađen postojeći placeholder |

| Instruktor dizajn | Ruta / ulaz | Stanje |
| --- | --- | --- |
| I01 Početna | `/home` | Placeholder |
| I02 Moj raspored | `/` | Postojeća implementacija |
| I03 Detalj vožnje | `/lessons/:lessonId` | Postojeća implementacija |
| I04 Završi sat | `/lessons/:lessonId/complete` | Placeholder samostalnog ekrana; stvarno završavanje ostaje u detalju |
| I05 Moji kandidati | `/candidates` | Postojeća implementacija |
| I06 Profil kandidata | `/candidates/:candidateId` | Placeholder; postojeća evidencija na `/candidates/:id/progress` |
| I07 Zahtjev termina | `/lessons/:lessonId/request` | Placeholder samostalnog ekrana; radnje ostaju u detalju |
| I08 Moja dostupnost | `/availability` | Placeholder |
| I09 Poruke | `/messages` | Placeholder |
| I10 Moj profil | `/profile` | Postojeći podaci profila; kompatibilna ruta `/settings` |
| I11 Sat je evidentiran | `/lessons/:lessonId/completed` | Placeholder; otvaranje ne evidentira sat |

| Kandidat dizajn | Ruta / ulaz | Stanje |
| --- | --- | --- |
| C01 Početna | `/` | Postojeća implementacija |
| C02 Moj put | `/journey` | Placeholder |
| C03 Moji termini | `/lessons` | Postojeća implementacija |
| C04 Zatraži vožnju | `/lessons/request` | Placeholder samostalnog ekrana; stvarni zahtjev ostaje u postojećem dijalogu |
| C05 Zahtjev je poslan | `/lessons/request-sent` | Placeholder; otvaranje ne šalje zahtjev |
| C06 Detalj termina | `/lessons/:lessonId` | Placeholder |
| C07 Moj ispit | `/exams` | Placeholder |
| C08 Dokumenti i uplate | `/documents-payments` | Placeholder |
| C09 Poruke | `/messages` | Placeholder |
| C10 Moj profil | `/profile` | Postojeća implementacija |

A04-R i C04-R su prilagodljive varijante istog ekrana, ne dodatne rute.
S01 je postojeća `/login`; S02–S09 su stanja, poruke i dijalozi, ne odredišta.
Postojeće funkcionalnosti nisu zamijenjene placeholderima. Ukupno je dodano
21 placeholder ruta (admin 7, instruktor 7, kandidat 7) uz postojeće admin
postavke i funkcionalnu rutu `/lessons/new`.

## Provjere

```sh
dart run melos run check
cd backend
mvn test
mvn -DskipTests package
```

Novi testovi pokrivaju filtere, navigaciju tjedana, očuvanje pogleda, svih pet
statusa, konflikt i ponovni pokušaj, očuvanje obrasca, grešku nakon uspješnog
spremanja, dvostruke akcije, zastarjele odgovore i zatvaranje Cubita.
Svaka aplikacija provjerava sve placeholder putanje; mobilni testovi provjeravaju
navigaciju kroz svih pet odredišta, uključujući tekst 2×.
Postojeće backend regresije dodatno provjeravaju promijenjenu dodjelu, školske
ovlasti, konkurentne rezervacije, statusne prijelaze i susjedne intervale;
novi testovi provjeravaju konkretne konfliktne poruke i filtre konačnih statusa.

Vizualni test renderira pravi admin navigacijski okvir, raspored i obrazac
na 1440, 390 i 360 px (posljednji s tekstom 2×). Slike se opcionalno stvaraju:

```sh
cd apps/admin_app
SCHEDULE_SCREENSHOTS=/tmp/auto-skola-issue7-previews flutter test test/schedule_visual_test.dart
```

Testovi backenda koriste H2 bez Flywaya. Nema nove migracije ni promjene
trajanja/statusnih pravila. Placeholder ne implementira odgovarajući budući
modul. Testovi i renderirane slike ne zamjenjuju povezani tok s produkcijskim
backendom ili provjeru na fizičkom mobilnom uređaju.

Rezultat 2026-09-18: format i četiri analize bez nalaza; svih **281 Flutter
testova** prolazi (admin 115, kandidat 50, instruktor 70, design system 46).
Prolaze **34 backend testa** i `mvn -DskipTests package`. Admin web build
uspješan uz postojeće upozorenje za obitelj `CupertinoIcons`. Pregledane su
renderirane slike rasporeda i obrasca; mobilni datum/vrijeme prilagođeni su
nakon vizualnog pregleda. Lokalne dokumentacijske poveznice i `git diff --check`
prolaze.
