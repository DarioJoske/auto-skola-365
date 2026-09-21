# Prilagodljiva navigacija i zajednička UI stanja

Implementacija zadatka [#5](https://github.com/DarioJoske/auto-skola-365/issues/5).
Figma reference: [BottomNavigation 20:23](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=20-23)
i [AdminSidebar 21:34](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=21-34),
pregledane 2026-09-17. Sadržaj i odredišta prilagođeni su postojećim rutama.
U #5 nisu dodani budući ekrani iz makete. Naknadni [zadatak #7](admin-schedule.md) dodaje placeholder rute kroz glavne navigacijske trake svih triju aplikacija (bez zasebnog kataloga ekrana).

## Ponašanje

| Površina | Ponašanje |
| --- | --- |
| Admin ≥1200 px | Sidebar 256 px, vidljive oznake i odabrano odredište. |
| Admin 600–1199 px | NavigationRail 80 px s tooltipovima i semantikom. |
| Admin <600 px | Navigacijska ladica, zatvaranje nakon odabira. |
| Instruktor | Donja navigacija: Raspored, Kandidati, Postavke. |
| Kandidat | Donja navigacija: Pregled, Termini, Moj profil. |
| Tipkovnica | Donja navigacija se skriva dok je tipkovnica otvorena; unos ostaje sačuvan. |
| Prvo učitavanje / osvježavanje | Zajednički indikator; postojeći sadržaj ostaje vidljiv tijekom osvježavanja. |
| Greška učitavanja | Backend poruka i gumb „Pokušaj ponovno” uz zadržani sadržaj. |
| Mutacija / istek sesije | Snackbar; kod 401 jasna poruka „Sesija je istekla. Prijavite se ponovno.” uz postojeću odjavu. |
| Otkazivanje termina | Potvrda ili odustajanje prije poziva Cubita. |
| Široka tablica | Vodoravno pomicanje preko `AppHorizontalScroll`; primjer u admin galeriji. |

Admin popisi koriste slivere kako bi kontrole, greška i rezultati bili dostupni
na nižem prozoru ili s većim tekstom. Instruktorov raspored dopušta pomicanje
zaglavlja i kalendara. Padajući izbornici prilagođavaju širinu i visinu tekstu.
Osvježavanje detalja termina zadržava formu s bilješkom. Portal zadržava podstablo
podataka tijekom osvježavanja. Postojeća auth pravila i čišćenje portala pri
401/403 ostaju na snazi.

Nema nove offline pohrane ni offline indikatora. Greška učitavanja sama po sebi
ne dokazuje da uređaj nema mrežu.

## Provjere

Iz korijena repozitorija:

```sh
dart run melos run check:design-system
```

Skripta provjerava format, analizu i cijele test suiteove design systema i sve
tri aplikacije. Novi/prošireni testovi pokrivaju:

- navigaciju na 1440, 1024, 390 i 360 px, tekst 1×/2× i tipkovnicu od 300 px;
- očuvanje unosa pri promjeni sidebar/rail/ladica i zatvaranje ladice;
- admin popise i kalendar na 1440/1024, te očuvanje pretrage i rezultata kroz
  učitavanje, grešku i ponovni pokušaj;
- instruktorov raspored i kandidate na 390/360 uz tekst 1×/2×;
- bilješku dovršavanja vožnje kroz osvježavanje, grešku i ponovno spremanje;
- odustajanje od otkazivanja i jedan poziv nakon potvrde;
- kandidatsku prijavu, prijelaze među svim postojećim odredištima i odjavu na
  390/360, 1×/2×, uz Android/iOS platformne varijante;
- vodoravno pomicanje do posljednjeg stupca te vidljivu poruku isteka sesije.

`packages/design_system/lib/previews.dart` daje interaktivne navigacijske
primjere. Pokrenuti `flutter widget-preview start` iz paketa. Test
`app_navigation_test.dart` također sprema slike u `build/previews/navigation-*.png`
za vizualni pregled; generirani PNG-ovi nisu izvorni kod.

Provjera širina i tipkovnice koristi Flutter widget testove. Vizualni pregled
renderiranih previewa ne zamjenjuje provjeru na fizičkom Android/iOS uređaju ili
povezani tok s produkcijskim backendom. Backend i API nisu mijenjani u #5.

Rezultat 2026-09-17: format i analiza bez nalaza; 230 testova prolazi (admin 68,
kandidat 49, instruktor 67, design system 46). Admin web build prolazi uz ranije
zabilježeno upozorenje o nepriloženoj obitelji `CupertinoIcons`; upozorenje nije
riješeno ovim zadatkom. Vizualno su pregledani generirani navigacijski previewi
za sve četiri širine, uključujući veliki tekst na 360 px.
