# Figma → Flutter mapiranje

Izvor: [365 Foundations, 9:8](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=9-8),
pročitano 2026-09-17. Svijetla tema je jedini Figma mode. Mapiranje ima ukupno
**57 varijabli = 18 primitive + 21 semantic + 18 dimensions**, bez dodavanja
izmišljenog tamnog moda.

## 18 primitive varijabli

Izvorni nazivi iz `365 Primitives` mapiraju se na
[AppPalette](lib/src/tokens/app_palette.dart). U komponentama se koriste
semantičke boje iz teme; paleta služi kao temelj aliasa.

| Figma | AppPalette | Vrijednost |
| --- | --- | --- |
| blue/600 | blue600 | #245EDB |
| blue/50 | blue50 | #E8EEFF |
| blue/900 | blue900 | #153A8A |
| white | white | #FFFFFF |
| slate/25 | slate25 | #F5F7FC |
| slate/50 | slate50 | #EDF1F7 |
| slate/900 | slate900 | #14213A |
| slate/600 | slate600 | #53617A |
| slate/400 | slate400 | #71809A |
| slate/100 | slate100 | #E4E9F2 |
| lime/300 | lime300 | #D7F46A |
| lime/950 | lime950 | #243200 |
| green/800 | green800 | #17613F |
| green/50 | green50 | #E4F3EC |
| amber/800 | amber800 | #805300 |
| amber/50 | amber50 | #FFF0CB |
| red/700 | red700 | #B3261E |
| red/50 | red50 | #FCE9E7 |

## 21 semantička varijabla

[AppColors](lib/src/tokens/app_colors.dart) čuva Figma aliase; tema ih izričito
prenosi na Material uloge. Seed se koristi samo za preostale Material uloge
koje Figma ne definira. Ne mijenja nijednu navedenu vrijednost.

| Figma `365 Color` | AppColors | Flutter odredište |
| --- | --- | --- |
| color/primary | primary | ColorScheme.primary |
| color/on-primary | onPrimary | ColorScheme.onPrimary |
| color/primary-container | primaryContainer | ColorScheme.primaryContainer |
| color/on-primary-container | onPrimaryContainer | ColorScheme.onPrimaryContainer |
| color/background | background | ThemeData.scaffoldBackgroundColor, ColorScheme.surfaceContainerLow |
| color/surface | surface | ColorScheme.surface |
| color/surface-container | surfaceContainer | ColorScheme.surfaceContainer |
| color/on-surface | onSurface | ColorScheme.onSurface |
| color/on-surface-variant | onSurfaceVariant | ColorScheme.onSurfaceVariant |
| color/outline | outline | ColorScheme.outline |
| color/outline-variant | outlineVariant | ColorScheme.outlineVariant |
| color/inverse-surface | inverseSurface | ColorScheme.inverseSurface |
| color/inverse-on-surface | inverseOnSurface | ColorScheme.onInverseSurface |
| color/accent | accent | ColorScheme.tertiary, tertiaryContainer |
| color/on-accent | onAccent | ColorScheme.onTertiary, onTertiaryContainer |
| color/success | success | AppSemanticColors.success |
| color/success-container | successContainer | AppSemanticColors.successContainer |
| color/warning | warning | AppSemanticColors.warning |
| color/warning-container | warningContainer | AppSemanticColors.warningContainer |
| color/error | error | ColorScheme.error, onErrorContainer |
| color/error-container | errorContainer | ColorScheme.errorContainer |

Tonal gumb koristi `secondaryContainer = primaryContainer` i
`onSecondaryContainer = primary`, što odgovara plavoj oznaci na svijetloplavoj
Figma podlozi. Status Info koristi tamniji `onPrimaryContainer`.

## 18 dimenzijskih varijabli

| Figma `365 Dimensions` | Flutter | Vrijednost |
| --- | --- | --- |
| space/0 | AppSpacing.none | 0 |
| space/4 | AppSpacing.xs | 4 |
| space/8 | AppSpacing.sm | 8 |
| space/12 | AppSpacing.space12 | 12 |
| space/16 | AppSpacing.md | 16 |
| space/24 | AppSpacing.lg | 24 |
| space/32 | AppSpacing.xl | 32 |
| space/48 | AppSpacing.xxl | 48 |
| space/64 | AppSpacing.xxxl | 64 |
| radius/4 | AppRadius.xs | 4 |
| control/field-height | AppSpacing.fieldHeight | 56 (osnovna visina) |
| control/menu-item-height | AppSpacing.touchTarget | 48 (minimum) |
| control/menu-max-height | AppSpacing.menuMaxHeight | 320 |
| radius/8 | AppRadius.sm | 8 |
| radius/12 | AppRadius.md | 12 |
| radius/20 | AppRadius.lg | 20 |
| radius/28 | AppRadius.xl | 28 |
| radius/999 | AppRadius.full | 999 |

`contentWidth = 1120` i `compactBreakpoint = 600` dodatne su
layout konstante, ne dio broja 57. `AppPage` koristi širinu roditelja, ne cijelog
prozora, i dopušta eksplicitnu širinu/padding.

## 10 tekstualnih stilova

[AppTypography](lib/src/tokens/app_typography.dart) koristi postojeći
`packages/auto_skola_design_system/SchoolSans` (Roboto). Nema preuzimanja fontova
u runtimeu. Svi stilovi imaju letterSpacing 0; `height = lineHeight / fontSize`.

| Figma | AppTypography | TextTheme primarno odredište | Font / visina / težina |
| --- | --- | --- | --- |
| 365/Display | display | displayLarge | 48 / 56 / 700 |
| 365/Headline | headline | headlineLarge | 32 / 40 / 700 |
| 365/Heading | heading | headlineSmall | 24 / 32 / 700 |
| 365/Title | title | titleLarge | 20 / 28 / 700 |
| 365/TitleSmall | titleSmall | titleMedium | 16 / 24 / 700 |
| 365/Body | body | bodyLarge | 16 / 24 / 400 |
| 365/BodySmall | bodySmall | bodyMedium | 14 / 20 / 400 |
| 365/Label | label | labelLarge | 14 / 20 / 700 |
| 365/Caption | caption | labelSmall | 12 / 16 / 700 |
| 365/FieldLabel | bodyLarge uz Materialovo skaliranje 0,75 i visinu 4/3 | InputDecorationTheme.floatingLabelStyle | 12 / 16 / 400 |

Preostali Material TextTheme slotovi koriste najbliži postojeći stil, bez novih
fontova/težina: displayMedium → Display, displaySmall → Headline,
headlineMedium → Heading, titleSmall → TitleSmall, bodySmall → BodySmall,
labelMedium → Label. Oznake polja koriste Materialovo smanjenje floating labela
s 16 na 12 px; ne postavlja se polaznih 12 pa nenamjerno dobije 9 px.

## 3 elevation stila

[AppElevation](lib/src/tokens/app_elevation.dart) čuva Figma `BoxShadow` vrijednosti.
`AppCard(elevation: ...)` ih koristi izravno; Material Card elevation ostaje 0
kako se sjene ne bi zbrajale. Broj levela nije Material z-koordinata.

| Figma | Flutter | Offset | Blur | Spread | Boja i alpha |
| --- | --- | --- | --- | --- | --- |
| 365/Elevation/1 | AppElevation.level1 | 0, 1 | 3 | 0 | #14213A / 8% |
| 365/Elevation/2 | AppElevation.level2 | 0, 4 | 12 | 0 | #14213A / 10% |
| 365/Elevation/3 | AppElevation.level3 | 0, 12 | 32 | 0 | #14213A / 16% |

Alpha je zaokružena na najbliži 8-bitni kanal. Zadane kartice bez sjene koriste
`AppElevation.none`. Dialog i Snackbar zadržavaju standardno Material ponašanje.

## Komponente i stanja

| Figma komponenta | Flutter mapiranje | Primjena / stanja |
| --- | --- | --- |
| Button, 13:2 | AppButton → FilledButton, FilledButton.tonal, OutlinedButton, TextButton | Enabled, hovered, focused, pressed, disabled, loading. |
| TextField, 13:24 | AppTextField → TextFormField, InputDecorationTheme | Outlined bez ispune, radius 4, osnovna visina 56; default/focus/error/disabled, validator i backend errorText. |
| DropdownField, 79:21 | AppDropdownFormField → DropdownMenu, FormField | Ista outlined geometrija; kontrolirani odabir, nullable opcija, validacija, reset, Escape i tipkovnica. |
| MenuItem, 77:8 | MenuItemButton / DropdownMenuEntry | Stavke najmanje 48 px; odabrana kvačica, fokus, disabled; prelamanje duljih oznaka. |
| Menu, 78:4 | MenuAnchor / DropdownMenu + MenuTheme | Standardna površina, radius 4, padding 8, elevation 2; najviše 320 px visine uz scrollbar. |
| Checkbox, 38:2376; Switch, 39:8 | Standardni Checkbox/CheckboxListTile i Switch/SwitchListTile | Material stanje i semantika; nije potreban paralelni wrapper. |
| StatusBadge, 15:10 | AppStatusBadge + AppTone | Info, success, warning, error, neutral; tekst uvijek ostaje vidljiv. |
| LessonCard, 15:11 | AppLessonCard | Podaci i akcija od pozivatelja, bez provjere ovlasti u paketu. |
| StatCard, 15:18 | AppStatCard | Label/value/detail; značenje i vremenski raspon daje pozivatelj. |
| ProgressCard, 16:3 | AppProgressCard | Omjer od pozivatelja, neograničen stvarni tekst, null cilj, osvježavanje. |
| ListItem, 16:10 | AppListItem | Avatar/leading, naslov, podnaslov, dodatak i InkWell akcija. Dodatak ispod teksta radi uskog prikaza. |
| InfoCard, 16:16 | AppInfoCard | Eyebrow/title/body/action. |
| DataRow, 17:6 | Material DataTable/DataRow/DataCell + AppStatusBadge + AppHorizontalScroll | Širine određuje tablica; horizontalni scroll na uskom prikazu. Primjer u admin galeriji. |
| CalendarEvent, 23:82 | AppCard s radius md, padding space12, bojom primaryContainer + tekstovi i AppStatusBadge | Kalendar aplikacije određuje geometriju i termine; novi kalendarski sustav nije uveden. |
| RouteBanner, 29:7 | AppCard s radius xl, inverseSurface + lokalizirani tekstovi | Sadržaj i raspored ostaju u ekranu aplikacije. |
| EmptyState, 37:4 | AppEmptyState | Naslov, opis i opcionalna akcija. Naslov ima heading semantiku. |
| Notice, 39:36; Error, 17:16 | AppNotice / AppInlineError | Error/warning/success/info/neutral; live-region poruka i opcionalni retry uz postojeći sadržaj. |
| Snackbar, 37:14 | showAppSnackBar / showSessionExpired + SnackBarThemeData | Prikazuje aplikacijski listener nakon promjene stanja. |
| ConfirmationDialog, 38:2354 | showAppConfirmation → AlertDialog + DialogThemeData | Tekstovi, potvrda i odustajanje iz aplikacije. |
| BottomNavigation, 20:23; NavigationItem, 20:12 | AppNavigationShell → NavigationBar/NavigationDestination | Osnovna visina 76 px; raste s tekstom, skriva se uz tipkovnicu. Izbor i go_router ostaju u aplikaciji. |
| AdminSidebar, 21:34; AdminNavigationItem, 21:33 | AppNavigationShell → ListTile / NavigationRail / Drawer | Sidebar 256 px od 1200, rail 80 px od 600, ladica ispod 600. Postojeća odredišta daje aplikacija. |
| MobileHeader, 20:13; AdminHeader, 23:69 | AppNavigationShell + TextTheme | Status bar ostaje platformi; ne kodira se Figma 9:41 ili baterija. |
| MaterialIcon, 19:6 | Icon / postojeći Material Icons | Pozivatelj bira glyph i semantičku oznaku; ne uvodi se novi font ikona. |

Gumbi imaju minimalno 48×48, ali rastu s tekstom. Material hover/pressed slojevi
zamjenjuju Figma smanjenje opacityja cijelog gumba, kako bi tekst ostao čitljiv.
Fokus dobiva obrub 3 px; filled/tonal koriste tamnoplavi fokus radi vidljivosti.
Loading zadržava boju varijante i tekst, prikazuje indikator te postavlja callback
na null. Greška radnje pripada `AppNotice`/SnackBaru; ne izmišlja se novo stanje
„error button”. Backend poruku i odluku o retryju daje aplikacija.

Komponente nemaju fiksnu visinu iz makete: sadržaj raste s lokalizacijom i
skaliranjem teksta. Omjer napretka mijenja samo indikator; nema unosa odrađenih
sati, automatske procjene spremnosti ili otkrivanja bilješki. Primjeri triju
aplikacija i provjere opisani su u [README-u](README.md).

## Korekcija izbornika i outlined polja — 2026-09-18

Primijenjene [Material 3 smjernice](https://m3.material.io/components/menus/guidelines).
Sva aplikacijska izborna polja koriste zajednički Material 3 wrapper; stari
`DropdownButtonFormField` i `PopupMenuButton` uklonjeni su iz aplikacijskih izvora.
Exposed menu prati širinu polja; overflow menu raste do 280 px. Standardni M3
izbornik sam prilagođava položaj prostoru. 56 px i 48 px nisu maksimalne visine:
veći font i više redaka povećavaju komponente. Standardne Material sjene izbornika
slijede elevation 2; Figma prikazuje odgovarajući projektni stil 365/Elevation/2.

Figma primjer otvorenog izbornika: [85:9](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=85-9).
Ažurirane su instance polja u adminu, instruktoru, kandidatu i prijavi. Produktni
primjeri u maketama ostaju podređeni [handoffu](../../docs/architecture/design-handoff.md).
