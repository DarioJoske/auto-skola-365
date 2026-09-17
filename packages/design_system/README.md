# Autoškola 365 design system

Zajednička Material 3 biblioteka za admin, instruktorsku i kandidatsku aplikaciju.
Task [#3](https://github.com/DarioJoske/auto-skola-365/issues/3) prenosi 53 Figma
varijable, 9 tekstualnih stilova i 3 elevation stila. Točno mapiranje i svjesne
prilagodbe Materialu opisane su u [Figma mapiranju](figma-mapping.md).

## Organizacija

```text
lib/
  design_system.dart          # javni export za aplikacije
  previews.dart               # zasebni, opcionalni Widget Preview ulaz
  src/
    tokens/                   # paleta, boje, razmaci, radijusi, tipografija, sjene
    theme/                    # Material tema, semantičke boje i tonovi
    components/               # jedna prezentacijska komponenta po datoteci
    preview/                  # odvojeni pokazni primjeri triju aplikacija i katalog
```

Aplikacije uvoze `package:auto_skola_design_system/design_system.dart`.
`previews.dart` nije dio glavnog exporta. Postojeći `AppCard`, `AppPage`,
`AppEmptyState`, `AppStatusBadge`, `AppSpacing` i `DrivingSchoolTheme` pozivi
ostaju kompatibilni. `AppStatusBadge.isPositive` ostaje podržan; novi pozivi
koriste `tone`, koji ima prednost ako su navedena oba parametra.

## Tema i komponente

- `DrivingSchoolTheme.light()` mapira Figma boje na `ColorScheme`, stilove na
  `TextTheme` i konfigurira standardne Material gumbe, polja, navigaciju,
  dijaloge i snackbare. Roboto koristi postojeće lokalne SchoolSans fontove
  težina 400/700 i njihovu [licencu](assets/fonts/Roboto_LICENSE.txt).
- `AppSemanticColors` proširuje temu bojama za uspjeh i upozorenje.
  `AppTone` bira vizualni ton, ne poznaje statuse backenda.
- `AppButton`: filled, tonal, outlined i text; `isLoading` prikazuje indikator
  i blokira ponavljanje akcije. `onPressed: null` isključuje gumb.
  `loadingLabel` dolazi iz aplikacije; zadano ostaje `label`.
- `AppTextField`: `TextFormField` s trajno vidljivom oznakom, kontrolerom ili
  početnom vrijednosti, validacijom, backend greškom i ulaznim opcijama.
  Kontroler i fokus koje proslijedi pozivatelj ostaju njegovo vlasništvo.
- `AppCard`: obrub, razmaci, boja, radijus i opcionalne Figma sjene;
  `onTap` koristi `InkWell` za Material interakciju i tipkovnicu.
- `AppPage`: širina do 1120 i prilagodljive margine prema širini roditelja;
  ne preuzima scroll. Za dugačak sadržaj aplikacija koristi `ListView` ili
  `SingleChildScrollView`.
- `AppNavigationShell`: admin sidebar/rail/ladica ili mobilna donja navigacija;
  callbackovi i `AppDestination` dolaze iz aplikacije. Navigacija ne posjeduje router.
- `AppLoadingState`, `AppInlineError`: prvo učitavanje, osvježavanje uz postojeći
  sadržaj i inline ponovni pokušaj. `showAppSnackBar`, `showSessionExpired` i
  `showAppConfirmation` standardiziraju povratne informacije i potvrde.
- `AppHorizontalScroll`: vodoravna traka i pomicanje širokih tablica/kontrola.
- `AppStatusBadge`: info/success/warning/error/neutral uz obavezni tekst.
- `AppEmptyState`, `AppNotice`, `AppInfoCard`: prazno stanje, inline obavijest
  ili opis sljedećeg koraka s opcionalnom akcijom.
- `AppLessonCard`: formatirano vrijeme, naslov, detalji, status, mjesto i akcija.
- `AppProgressCard`: tekstualni zbroj i opcionalni omjer; samo prikazna traka
  ograničava omjer na 0–1, stvarni tekst ostaje npr. `37 / 35`. `progress: null`
  izostavlja traku kada cilj nije poznat. `isLoading` zadržava postojeći sadržaj.
- `AppStatCard` i `AppListItem`: pokazatelji i prilagodljivi retci.
  Za tablice koristi se standardni `DataTable`/`DataRow`, s vodoravnim scrollom.

Komponente nemaju mrežu, spremište, Cubit/BLoC, rute, DTO-e ni pravila obračuna.
Pozivatelj daje podatke, lokalizirane tekstove i callbackove; značajka prosljeđuje
akcije svojem Cubitu/BLoCu. Poslovna pravila iz
[handoffa](../../docs/architecture/design-handoff.md) ostaju u aplikacijama i
backendu: 60 minuta po terminu, backend zbroj sati, interne bilješke i početna
lozinka. Komponente same ne određuju smije li se sat završiti.

## Primjena

```dart
MaterialApp(
  theme: DrivingSchoolTheme.light(),
  home: Scaffold(
    body: AppPage(
      child: AppLessonCard(
        timeLabel: '16:30 – 17:30',
        title: 'Ana Horvat',
        details: 'Vožnja · B kategorija · 60 minuta',
        statusLabel: 'Čeka potvrdu',
        statusTone: AppTone.warning,
      ),
    ),
  ),
);
```

Trajanje, statusi i tekstovi u ovom primjeru ilustriraju postojeći ugovor;
produkcijska aplikacija ih dobiva iz svojeg stanja. Datume i vrijeme formatira
aplikacija svojim postojećim `MaterialLocalizations`/lokalizacijama.

Pokazni primjeri koji se analiziraju i testiraju:

| Aplikacija | Primjer | Što pokazuje |
| --- | --- | --- |
| Admin | [admin_example.dart](lib/src/preview/admin_example.dart) | Pokazatelj, formu, spremanje/grešku/retry uz očuvan unos i tablični redak. |
| Instruktor | [instructor_example.dart](lib/src/preview/instructor_example.dart) | Potvrđeni termin, internu bilješku, nedostupno završavanje i upozorenje. |
| Kandidat | [candidate_example.dart](lib/src/preview/candidate_example.dart) | Backend zbroj, zahtjev koji čeka potvrdu, info karticu i prazno stanje. |
| Katalog | [component_catalog.dart](lib/src/preview/component_catalog.dart) | Četiri vrste gumba, disabled/loading stanja, pet tonova, polja i sjene. |

Iz direktorija paketa pokrenite `flutter widget-preview start` i otvorite
`lib/previews.dart`. Anotacije koriste API dostupan u Flutteru 3.35.7 / Dartu
3.9.2, bez novijih `group`/`MultiPreview` API-ja. Interakcije primjera rade samo
u memoriji; ne pišu podatke aplikacije. U katalogu fokus provjerite tipkom Tab,
a pritisak i hover tipkovnicom ili mišem. Kandidatski preview uključuje i 2× tekst.

## Provjera

Iz korijena repozitorija:

```bash
dart run melos run check:design-system
```

Naredba obuhvaća format, analizu i testove paketa te svih triju aplikacija.
Za lokalni rad u paketu: `dart format lib test`, `flutter analyze`, `flutter test`.
Testovi provjeravaju akcije i fokus gumba, blokiranje ponavljanja, validaciju i
čuvanje unosa, osvježavanje napretka, semantičke oznake te prikaze na 320/390/1024
uz 2× tekst. PNG prikazi za vizualni pregled stvaraju se u `build/previews/`
uz stvarne Roboto fontove; nisu automatski golden baseline niti dokaz potpune
pristupačnosti. `test/previews_test.dart` provjerava i admin tijek spremanja,
greške i ponovnog pokušaja.

Sve tri aplikacije već koriste zajedničku temu. Ovaj zadatak proširuje paket;
zamjena pojedinačnih ekrana novim karticama i poslovni tokovi pripadaju sljedećim
zadacima. Nove ovisnosti i nadogradnja SDK-a nisu potrebni.

Previewi `adminNavigationPreview` (1440/1024) i `mobileNavigationPreview`
(390/360 uz dvostruki tekst) prikazuju navigaciju, unos, osvježavanje, grešku,
ponovni pokušaj i potvrdu. Ne trebaju mrežu ni prijavu. Detalji provjera su u
[vodiču #5](../../docs/development/responsive-shells.md).
