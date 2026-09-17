# Kandidatska aplikacija

Flutter aplikacija isključivo za Android i iOS, s prijavom, pregledom sljedeće vožnje,
poviješću termina, odrađenim satima i zahtjevom za termin.

## Pokretanje

Pokrenite backend s najnovijim kodom i migracijama. Iz ovog direktorija:

```bash
flutter devices
flutter run -d <mobile-device-id> --dart-define=API_BASE_URL=http://localhost:8080
```

Iz korijena repozitorija na macOS/Linux možete koristiti Melos, s ID-em
Android/iOS uređaja iz `flutter devices`:

```bash
CANDIDATE_DEVICE_ID=<mobile-device-id> API_BASE_URL=http://localhost:8080 melos run dev:candidate
```

Zamijenite `<mobile-device-id>` stvarnim ID-em uređaja. `build:web` gradi samo
admin aplikaciju; kandidatska aplikacija nije podržana web platforma.

Za Android emulator koristite `http://10.0.2.2:8080`. Za fizički uređaj postavite
adresu backenda dostupnu s uređaja. Produkcijski backend treba HTTPS.

U admin aplikaciji otvorite kandidata, unesite email i neobavezno polje
„Lozinka za kandidatsku aplikaciju” (8–72 znaka), pa spremite. Time se kreira
novi račun s ulogom kandidata i povezuje s kandidatom. Postojeći tuđi račun
ne povezuje se automatski. Za već aktivirani kandidatski račun admin može
postaviti novu lozinku; prazno polje zadržava postojeću. Promjena se odnosi
samo na povezani kandidatski račun ove škole. Email za prijavu nakon
aktivacije prikazan je na kandidatu; kontaktni email je zaseban podatak.

Kandidat se prijavljuje tim podacima. Za zahtjev za termin mora imati dodijeljenog
aktivnog instruktora. Zahtjev dobiva status `REQUESTED` i čeka potvrdu instruktora.
Dovršene vožnje ulaze u isti brojač sati koji koriste admin i instruktor.

Vizualne osnove nalaze se u [zajedničkom design systemu](../../packages/design_system/README.md).
Provjere: `dart format lib`, `flutter analyze`, `flutter test`.
Android/iOS projekti su inicijalizirani; distribucija i potpisivanje nisu dio ove promjene.
