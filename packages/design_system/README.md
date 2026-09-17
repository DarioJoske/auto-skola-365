# Autoškola 365 design system

Mala zajednička Flutter biblioteka za admin, instruktorsku i kandidatsku aplikaciju.

- `DrivingSchoolTheme.light()`: plava `#245EDB`, svijetla podloga `#F5F7FC`, bijele kartice, obrubi i fokusna stanja.
- `AppSpacing`: 4 / 8 / 16 / 24 / 32 / 48; maksimalna širina sadržaja 1120.
- Tipografija: lokalno uključen Roboto (SchoolSans), osnovna i podebljana težina.
  Licenca je uz fontove u `assets/fonts/Roboto_LICENSE.txt`.
- `AppCard`: prozračna kartica s obrubom i unutarnjim razmakom.
- `AppPage`: prilagodljiva širina i margine sadržaja.
- `AppEmptyState`: prazno stanje ili greška s opcionalnom akcijom.
- `AppStatusBadge`: tekstualna oznaka statusa, uz boju kao dodatni signal.

Nova kandidatska aplikacija koristi temu i komponente. Admin i instruktor koriste
zajedničku temu; njihov postojeći raspored ekrana ostaje zaseban korak redizajna.
Poslovna logika, tekstovi specifični za značajku i navigacija ostaju u aplikacijama.

Primjer:

```dart
MaterialApp(theme: DrivingSchoolTheme.light(), home: Scaffold(
  body: AppPage(child: AppCard(child: Text('Odrađeni sati'))),
));
```

Provjere: `dart format lib`, `flutter analyze`, `flutter test`.
