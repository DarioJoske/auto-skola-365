# Instruktorski dnevni rad i zaključivanje — task #9

Implementacija obuhvaća I01–I06 i I11. Primjenjuju se
[pravila predaje dizajna](../architecture/design-handoff.md): ilustrativna vozila,
lokacije, teme, ručni unos sati i javna bilješka iz Figme nisu API ugovor.

## Zasloni i ponašanje

| Ruta | Ponašanje |
| --- | --- |
| `/home` | Zadano odredište nakon prijave. Današnji termini, broj potvrđenih/održanih vožnji, sljedeća potvrđena vožnja i zahtjevi u sljedećih sedam kalendarskih dana. |
| `/` | Dnevni/tjedni raspored kao lista kartica, datum, svih pet statusa i postojeća rezervacija termina. |
| `/lessons/:lessonId` | Vlastiti termin, aktualni sati, interne bilješke, profil kandidata, potvrda zahtjeva i otkazivanje uz dijalog. |
| `/lessons/:lessonId/complete` | Samostalan obrazac s neobaveznom internom bilješkom do 2000 znakova. Spremanje je dostupno za potvrđenu vožnju nakon `endAt`. |
| `/lessons/:lessonId/completed` | Čita termin i potvrđuje samo stvarni `COMPLETED`; zasebno učitava aktualne sate s backenda. Izravno otvaranje ne mijenja evidenciju. |
| `/candidates` | Dodijeljeni kandidati, pretraga i sklopivi postojeći filtri; kartica s ukupnim odrađenim satima vodi na profil. |
| `/candidates/:candidateId` | Aktualna kategorija i sati, kontakt, interna bilješka, rezervacija s unaprijed odabranim kandidatom i vlastiti termini s bilješkama završavanja. |

Postojeće `/candidates/:id/progress` i `/lessons/:id/progress` ostaju podržane.
Poruke ostaju označene kao priprema. Dostupnost i zasebni prikaz zahtjeva
implementirani su u [tasku #10](request-availability.md); detalj termina vodi
na obradu zahtjeva. Nema izmišljenih podataka o
vozilima, slobodnim terminima ili automatskoj spremnosti za ispit.

## API i granice pristupa

Dodani su read-only API-ji:

- `GET /api/schools/{schoolId}/candidates/instructor/{candidateId}`: aktivni
  instruktor iz prijave, aktivna ovlast `lessons.view_assigned`, kandidat iz
  navedene škole i aktualna dodjela tom instruktoru.
- `GET /api/schools/{schoolId}/lessons/instructor/candidates/{candidateId}`:
  iste granice, uz dohvat samo termina zapisanih na tom instruktoru, silazno po
  početku. Povijest se ne ograničava na trenutnu kategoriju ili posljednjih
  sedam dana; uključuje i buduće termine te svih pet statusa.

Nakon promjene dodjele novi instruktor vidi profil i ukupne sate, ali ovaj
endpoint ne otkriva bilješke termina prethodnog instruktora. Stari instruktor
više nema pristup novom profilu/povijesti. Postojeći pristup vlastitom terminu i
pravila njegova završavanja ostaju zaseban ugovor.
Popis dodijeljenih kandidata sada također zahtijeva aktivan instruktorski profil.

Završavanje i izračun sati koriste postojeće API-je. Backend je konačni
provjeravatelj statusa, vlasništva i vremena: zaključava redak termina, dopušta
samo `CONFIRMED` → `COMPLETED` te odbija ponavljanje s `409`. Klijent ne šalje
ručni broj sati, temu ni procjenu spremnosti. Jedna dovršena vožnja doprinosi
jednom nastavnom satu trenutačne kategorije; potvrda prikazuje dohvaćeni zbroj
bez obećanja povećanja za povijesnu kategoriju. Nema promjene sheme ili migracije.

## Stanje i osvježavanje

Cubit za dnevni pregled dohvaća kalendarskih sedam dana. Profil učitava kandidata
i zatim autoriziranu povijest kroz use caseove i repozitorije. Stara asinkrona
učitavanja ne prepisuju novija; zatvoreni Cubiti ne emitiraju. Oporavljiva greška
čuva prethodne podatke, a uskraćeni pristup uklanja zaštićene podatke.

Ponovljeni pritisak tijekom spremanja se zanemaruje. Bilješka ostaje u obrascu
nakon greške. Uspjeh zamjenjuje obrazac potvrdom; nova stranica ponovno dohvaća
termin i sate. Povratak iz detalja/profila osvježava izvorni popis i evidenciju.
Povratak na Danas stvara aktualni pregled. Pogreška osvježavanja sati ostaje
vidljiva uz zaseban ponovni pokušaj, bez ponavljanja upisa sata.

`401` prikazuje poruku o isteku sesije prije odjave. Greške učitavanja imaju
inline prikaz i retry, a greške radnji snackbar s porukom backenda.

## Provjere

Izvršeno 2026-09-23:

- Formatiranje Dart izvora i testova, `flutter analyze --no-pub`.
- Cijeli `flutter test --no-pub` u `apps/instructor_app`: 84 testa prolaze.
- `mvn test`: 37 testova prolazi; `mvn -DskipTests package` uspješan.
- Vizualni pregled I01–I06 i I11 na 390 × 844; widget provjere i uz tekst 2×.
- `git diff --check` i provjera lokalnih dokumentacijskih poveznica.

`instructor_workflow_test.dart` spaja pravi router, stranice, Cubite, use caseove,
repozitorije i Dio s testnim HTTP adapterom. Pokriva zaključivanje, potvrdu,
profil/povijest, osvježene sate, ponovni pokušaj, trajanje termina i izravno
otvaranje potvrde. Cubit testovi pokrivaju dvostruke radnje, zakašnjele odgovore,
zatvaranje i očuvanje podataka. Backend integracijski testovi provjeravaju
izolaciju škole/instruktora, promjenu dodjele, neaktivan profil i ponovljeno
zaključivanje, uz postojeće konkurentne regresije.

Testovi backenda koriste postojeću H2 konfiguraciju. Ovim zadatkom nije pokrenut
zaseban test na PostgreSQL-u ni aplikacija na fizičkom uređaju/emulatoru.
Flutter povezani tok koristi testne HTTP odgovore, a nije test protiv živog
backenda. Za ponavljanje vizualnih snimki sa sintetičkim podacima:

```bash
mkdir -p /tmp/instructor-screenshots
cd apps/instructor_app
INSTRUCTOR_SCREENSHOTS=/tmp/instructor-screenshots flutter test test/instructor_workflow_test.dart
```

## Izvori

- [GitHub #9](https://github.com/DarioJoske/auto-skola-365/issues/9).
- Figma [I01](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-641),
  [I02](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-710),
  [I03](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-777),
  [I04](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-844),
  [I05](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-904),
  [I06](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-983),
  [I11](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=43-564).
