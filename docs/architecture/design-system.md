# Zajednički design system

Odluka: 2026-09-17. Koristimo mali Flutter paket `packages/design_system` za
boje, tipografiju, razmake, temu i ponovljive prezentacijske komponente.

Sve tri aplikacije ovise o [paketu](../../packages/design_system/README.md).
Sve tri aplikacije koriste `AppNavigationShell`: admin prikazuje sidebar od
256 px na širini ≥1200, kompaktnu traku od 80 px na 600–1199 i ladicu ispod
600 px. Kandidat i instruktor koriste donju navigaciju za postojeća odredišta;
otvorena tipkovnica je privremeno skriva. Rute, auth i odabir odredišta ostaju
u aplikacijama. Paket nema API, stanje korisnika ili poslovnu logiku.

Proširena specifikacija za sve tri aplikacije nalazi se u
[Figma projektu](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc).
Implementacija cijele biblioteke i dodatnih ekrana vodi se kroz
[GitHub Project](https://github.com/users/DarioJoske/projects/2).
Paket sada mapira 57 varijabli, 10 tekstualnih stilova i 3 elevation stila
te nudi gumbe, polja, statuse, retke, kartice i inline obavijesti. Točno
[Figma → Flutter mapiranje](../../packages/design_system/figma-mapping.md)
razdvaja zajedničke komponente od standardnih Material widgeta i aplikacijskih
shellova. Pokazni primjeri za sve tri aplikacije nalaze se u `lib/previews.dart`
paketa. Puni rasporedi Figma ekrana još nisu preneseni u aplikacije.

Za implementaciju blueprinta vrijedi
[design handoff za termine, sate i pristup](design-handoff.md), usklađen u
zadatku #2. Makete s 90 minuta / 2 sata, javnom bilješkom ili pozivnicom nisu
aktualni API ugovor: ostaju 60 minuta / 1 sat, interne bilješke i aktivacija
početnom lozinkom. Handoff navodi statuse, ovlasti i potrebne prilagodbe ekrana.

Kandidatski backend koristi identitet iz JWT-a i aktivno članstvo škole;
`GET /api/schools/{schoolId}/candidate-portal` vraća samo povezani kandidatov
pregled i termine, bez internih napomena. `lessons.reserve_own` je postojeća
kandidatska dozvola za taj pristup i slanje zahtjeva za vožnju.

Pristup se aktivira kroz admin spremanje kandidata uz `loginPassword`;
postojeći korisnički račun se ne preuzima na temelju email adrese.
Admin može promijeniti lozinku povezanog kandidatskog računa svoje škole;
prazno polje zadržava postojeću lozinku. Email za prijavu ostaje odvojen od
kontaktnog emaila kandidata. Pozivnice, samostalni oporavak lozinke, ispiti
i poruke ostaju izvan ovog prvog opsega.

## Provjera zajedničkih promjena

Iz korijena projekta pokrenite `melos run check:design-system`. Skripta
provjerava formatiranje, analizu i testove paketa te svih aplikacija koje ga
koriste. Razvojne naredbe i budući CI koraci opisani su u
[Melos vodiču](../development/melos.md).

## Zajednička stanja i osvježavanje (#5)

`AppLoadingState` razlikuje prvo učitavanje i nenametljivu traku osvježavanja.
`AppInlineError` prikazuje poruku backenda i ponovni pokušaj, `AppEmptyState`
prazan uspješan rezultat. `showAppSnackBar`, `showSessionExpired` i
`showAppConfirmation` dijele Material izgled i ponašanje. Otkazivanje termina
u adminu i instruktoru traži potvrdu prije poziva postojećeg Cubita.

Admin popisi i instruktorov raspored imaju pomične kontrole i sadržaj.
Osvježavanje zadržava postojeće popise/kalendar, kandidatski portal i unesenu
bilješku dovršavanja vožnje. Greška osvježavanja ostavlja podatke uz inline
ponovni pokušaj. Autorizacijski redirect ostaje u routeru. Nema nove offline
pohrane ni oznake „offline”: zadržavanje podataka u memoriji nije dokaz offline
rada. Široke tablice koriste `AppHorizontalScroll`.

[Provjere navigacije i stanja](../development/responsive-shells.md) opisuju
pokretanje testova, previewe, pregledane širine i ograničenja provjere.

## Izbornici i outlined polja — 2026-09-18

Prema [Material 3 smjernicama za izbornike](https://m3.material.io/components/menus/guidelines),
izbornici su privremene površine usidrene uz kontrolu. Sve tri aplikacije koriste
outlined polja bez ispune, s radiusom 4 i osnovnom visinom 56 px. Dropdowni u adminu
i instruktoru prešli su na `AppDropdownFormField` (Material 3 `DropdownMenu`), a
kalendarski izbornici na `MenuAnchor` i `MenuItemButton`. Kandidatska polja nasljeđuju
istu zajedničku temu. Nema novih ovisnosti ni promjene poslovnih pravila.

Izborna polja čuvaju validaciju, prazni odabir, resetiranje ovisnog kandidata i
onemogućena stanja. Escape i klik izvan izbornika vraćaju potvrđeni odabir.
Izbornik prati širinu polja, ograničen je na 320 px visine i ima scrollbar;
48 px je najmanja visina stavke. Uvećanje teksta i više redaka ostaju podržani.

Figma `TextField` i sve njegove instance ažurirani su; dodani su `DropdownField`,
`MenuItem`, `Menu` i [otvoreni primjer](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=85-9).
Specifikacija tokena i stanja nalazi se u [mapiranju](../../packages/design_system/figma-mapping.md).
