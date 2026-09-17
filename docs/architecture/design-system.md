# Zajednički design system

Odluka: 2026-09-17. Koristimo mali Flutter paket `packages/design_system` za
boje, tipografiju, razmake, temu i ponovljive prezentacijske komponente.

Sve tri aplikacije ovise o [paketu](../../packages/design_system/README.md).
Kandidatska aplikacija prva primjenjuje novi raspored: početni pregled, termini
i profil; na mobitelu donja navigacija, na širokom ekranu bočna navigacija.
Postojeći admin i instruktor preuzimaju temu, a promjene rasporeda rade se
postupno po ekranu. Paket nema API, stanje korisnika ili poslovnu logiku.

Proširena specifikacija za sve tri aplikacije nalazi se u
[Figma projektu](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc).
Implementacija cijele biblioteke i dodatnih ekrana vodi se kroz
[GitHub Project](https://github.com/users/DarioJoske/projects/2).
Paket sada mapira svih 53 varijable, 9 tekstualnih stilova i 3 elevation stila
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
