# Melos razvojni vodič

## Što je uvedeno

Dart workspace obuhvaća tri aplikacije (`admin_app`, `instructor_app`,
`candidate_app`) i `packages/design_system`. Pub upravlja zajedničkim
razrješavanjem ovisnosti i root lockfileom. Melos upravlja razvojnim naredbama.
Konfiguracija je u [root pubspec.yaml](../../pubspec.yaml); zaseban `melos.yaml`
ne koristi se. Projekt koristi točno Melos 8.6.0 radi ponovljivosti.
Backend ostaje Spring Boot/PostgreSQL projekt s Mavenom.

## Instalacija i priprema

Koristite Dart iz istog Flutter SDK-a kojim razvijate aplikacije. Deklarirani
Dart raspon projekta je `^3.9.2`; zaseban SDK manager trenutačno nije konfiguriran.
Iz korijena repozitorija:

```bash
dart pub global activate melos
flutter pub get
melos --version
melos list
```

Globalna instalacija preuzima aktualnu dostupnu verziju. Unutar repozitorija
Melos launcher koristi projektnu verziju (8.6.0). Istu projektnu naredbu možete
pokrenuti kao `dart run melos`, bez oslanjanja na globalni executable.
Commitajte root `pubspec.lock` pri promjeni ovisnosti.

Ako `melos` nije pronađen, na macOS/Linux dodajte u konfiguraciju ljuske
(npr. `~/.zshrc`) pa otvorite novi terminal:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

Ako je postavljen `PUB_CACHE`, koristite njegov `bin` direktorij.
Na Windowsu dodajte pub cache `bin` u korisnički PATH (zadano
`%LOCALAPPDATA%\Pub\Cache\bin`). Flutter SDK `bin` također mora biti u PATH-u.

`flutter pub get` dovoljan je za postojeći workspace. `melos bootstrap` može
se koristiti za pripremu, ali zasad nema dodatnih bootstrap hookova niti
centralnog prepisivanja verzija ovisnosti.

## Dostupne naredbe

Sve naredbe pokreću se iz korijena repozitorija.

| Naredba | Ponašanje |
| --- | --- |
| `melos run format` | Formatira `lib` i `test` svih Flutter paketa; mijenja datoteke. |
| `melos run format:check` | Provjerava iste direktorije bez izmjena; neuspjeh ako format nije ispravan. |
| `melos run analyze` | Izvršava `flutter analyze --no-pub` u svakom Flutter paketu. |
| `melos run test` | Izvršava `flutter test --no-pub` u svim Flutter paketima s direktorijem `test`. |
| `melos run check` | Redom format-check, analiza i testovi; prekida nakon greške. |
| `melos run check:design-system` | Za design system i sve njegove ovisne pakete izvršava format-check, analizu i testove. |
| `melos run build:web` | Izgrađuje samo admin web aplikaciju. |
| `melos run dev:candidate` | Pokreće kandidatsku aplikaciju na mobilnom uređaju zadanom kroz `CANDIDATE_DEVICE_ID`. |
| `melos run test:backend` | Pokreće `mvn test` u `backend/`; zahtijeva Java/Maven okruženje. |

Flutter zadaci izvršavaju se sekvencijalno i prekidaju nakon greške.
`dev:candidate` nasljeđuje terminal: `r` pokreće hot reload, `R` hot restart,
a `q` završava aplikaciju. Pokrenite backend zasebno prema [README-u](../../README.md).
Prije pokretanja postavite `CANDIDATE_DEVICE_ID` na ID Android/iOS uređaja iz
`flutter devices`. Skripta bez njega prekida s jasnom porukom. `API_BASE_URL`
može se zadati kroz okolinu, a zadano je `http://localhost:8080` (iOS simulator).
Android emulator koristi `http://10.0.2.2:8080`; fizički uređaj treba mrežno
dostupnu adresu backenda. Primjeri pokretanja nalaze se u
[kandidatskoj aplikaciji](../../apps/candidate_app/README.md).

Prije provjera nakon promjene ovisnosti pokrenite `flutter pub get`.
`check` ne uključuje buildove ni Maven testove; za njih postoje zasebne skripte.
Buildovi ne objavljuju aplikacije niti konfiguriraju potpisivanje.

## Promjene design systema i novi paketi

Nakon promjene zajedničke teme ili komponente pokrenite:

```bash
melos list --scope=auto_skola_design_system --include-dependents
melos run check:design-system
```

Odabir trenutno uključuje sva četiri paketa. Testovi ne zamjenjuju vizualni
pregled relevantnih ekrana. Pročitajte [odluku o design systemu](../architecture/design-system.md).

Novi paket dodajte u root `workspace`, postavite `resolution: workspace` u
njegovom pubspecu i deklarirajte stvarne ovisnosti. Flutter paketi ulaze u
opće skripte automatski. Skripte formatiranja očekuju `lib` i `test` direktorije;
pri dodavanju paketa drugačije strukture prilagodite odabir. Web build eksplicitno
odabire samo `auto_skola_365_admin_app`. Kandidatska i instruktorska aplikacija
namijenjene su isključivo Androidu i iOS-u; obje ostaju uključene u analizu i testove.
Budući čisti Dart paketi trebaju svoje `dart analyze`/`dart test` skripte.

## Kada projekt naraste — još nije implementirano

- **CI prema promjenama:** kombinirati `--diff=<base>...HEAD` s
  `--include-dependents`. Base mora odgovarati ciljnoj grani PR-a i biti dostupan
  u CI checkoutu. Git diff filter ne služi provjeri nespremljenih lokalnih izmjena.
- **Pune provjere zajedničkih promjena:** promjena root lockfilea, pubspeca,
  zajedničkih lint pravila, SDK-a ili CI konfiguracije mora pokrenuti sve pakete.
- **Paralelizam i cache:** izmjeriti trajanje i memoriju prije povećanja broja
  paralelnih procesa; definirati CI cache ključeve prema OS-u, SDK-u i lockfileu.
- **Centralne verzije ovisnosti:** po potrebi koristiti bootstrap konfiguraciju
  za usklađivanje zajedničkih dependency constraints. Bootstrap tada mijenja
  pubspec datoteke, pa promjene treba pregledati i commitati.
- **Zaključavanje SDK-a:** odabrati jednu Flutter verziju za lokalni razvoj i CI,
  primjerice kroz FVM, uz dokumentiran postupak nadogradnje.
- **Generiranje koda:** dodati skripte tek kad uvedemo generatore; koristiti
  filtre prema dependencyju i redoslijed prema grafu ovisnosti gdje je potreban.
- **Verzioniranje i changelogovi:** dogovoriti Conventional Commits i neovisne
  verzije aplikacija/paketa prije automatizacije; privatni paketi zahtijevaju
  eksplicitno uključivanje u Melos version postupak.
- **Distribucija:** odvojeno definirati web hosting, Android/iOS potpisivanje,
  tajne i release odobrenja. Melos skripte same ne postavljaju distribuciju.

## Službeni izvori

- [Melos setup](https://melos.invertase.dev/getting-started)
- [Skripte](https://melos.invertase.dev/configuration/scripts)
- [Filtri](https://melos.invertase.dev/filters)
- [Migracije](https://melos.invertase.dev/guides/migrations)
- [Dart workspaces](https://dart.dev/tools/pub/workspaces)
