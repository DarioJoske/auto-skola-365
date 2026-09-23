# MVP — stanje razvoja i nastavak

Ažurirano: 2026-09-18. Ovaj pregled opisuje kod pripremljen za novi PR prema
`main`. Poslovna pravila nalaze se u [MVP specifikaciji](mvp-product-spec.md), a
ugovori endpointa u [API dokumentaciji](../architecture/api.md).

## Dopuna 2026-09-23 — task #8: kandidati, profil i upis (lokalne izmjene)

Admin popis kandidata sada ima tablične retke, stvarne backend zbrojeve sati,
filtre i lokalnu paginaciju. Profil prikazuje kontaktni i prijavni e-mail,
cilj sati, mjesečnu evidenciju vožnji i interne bilješke. Samostalni upis
zamjenjuje placeholder. Dokumenti, uplate i poruke jasno su označeni kao
nedostupni; ostaje aktivacija lozinkom bez slanja pozivnice.
[Ponašanje, razlike prema maketama i provjere](../development/admin-candidates.md).

## Dopuna — task #7: raspored, obrazac i rute dizajna

Admin raspored dobio je tjedne kartice i filtre svih statusa, prilagodljivi
obrazac i konkretne konflikte uz očuvanje unosa. Sve tri aplikacije imaju
rute za preostale ekrane (admin profil i upis naknadno implementirani u #8); glavna odredišta dostupna su kroz
navigacijske trake prema Figmi, bez zasebnog kataloga. Budući moduli
ostaju neimplementirani. [Ponašanje, mapa ekrana i provjere](../development/admin-schedule.md).

## Dopuna — task #6: operativni admin pregled

Početni pregled škole sada učitava stvarne pokazatelje, termine i stavke za
pažnju. Instruktori imaju pretragu, popis dodijeljenih kandidata i potvrđeno
tjedno opterećenje. Dodani su školski agregacijski endpointovi i poveznice na
filtrirane postojeće ekrane. Detalji i definicije: [admin pregled](../development/admin-overview.md).
Ova dopuna zamjenjuje raniju stavku o nedovršenom početnom admin pregledu.

## Dovršeno u kodu

- Admin upravlja kandidatima i instruktorima, dodjeljuje instruktora te rezervira
  termine uz filtriranje kandidata prema odabranom instruktoru.
- Instruktor pregledava vlastiti raspored, detalje i dodijeljene kandidate,
  rezervira vožnju, potvrđuje zahtjev, otkazuje i završava vlastiti odrađeni sat.
- Završavanje je dopušteno nakon isteka potvrđenog termina, uz neobaveznu bilješku
  i vrijeme evidentiranja. Završeni sat nije moguće ponovno završiti ili mijenjati.
- Evidencija odrađenih sati zamijenila je raniji unos procjena po vještinama.
  Admin, instruktor i kandidat vide broj završenih vožnji u aktualnoj kategoriji.
  Jedan završeni termin od 60 minuta vrijedi jedan nastavni sat; zadani cilj za
  B kategoriju je 35, a admin može postaviti pozitivan individualni cilj.
- Kandidatska aplikacija ima prijavu, početni pregled, termine, zahtjev za vožnju,
  profil i odjavu. Backend izvodi identitet kandidata iz prijavljenog korisnika i
  vraća samo njegove podatke, bez internih bilješki.
- Admin aktivira pristup novom kandidatskom računu početnom lozinkom i može
  promijeniti lozinku povezanog kandidatskog računa svoje škole. Postojeći račun
  ne preuzima se prema email adresi; kontaktni email ostaje odvojen od prijavnog.
- Zajednički paket `packages/design_system` sadrži temu, boje, tipografiju,
  razmake i osnovne komponente. Sve tri aplikacije koriste zajedničku temu.
- Melos provjerava formatiranje, analizu i testove sva četiri Flutter paketa.
- Asinkroni tokovi imaju regresijske testove za pogreške, ponovljene radnje,
  zakašnjele odgovore i zatvaranje ekrana.

## Provjere ovog PR-a

- `dart run melos run check`: formatiranje i analiza bez nalaza; 74 testa prolaze
  (admin 18, kandidat 20, instruktor 34, design system 2).
- `mvn test`: 15 testova prolazi. Integracijski testovi koriste H2, bez Flywaya.
- `mvn -DskipTests package`: uspješna izrada backend paketa.
- `dart run melos run build:web`: uspješan admin web build; alat prijavljuje
  upozorenje o nedostajućoj CupertinoIcons font obitelji.
- Pokretanje sastavljenog backenda na zasebnom privremenom PostgreSQL-u 16:
  svih 12 Flyway migracija uspješno primijenjeno na praznu bazu, Hibernate
  validacija sheme i podizanje aplikacije uspješni. Razvojna baza nije mijenjana.

## Dopuna 2026-09-17 — zadatak #4 (lokalne izmjene)

- Spriječene su konkurentne rezervacije istog kandidata ili instruktora,
  uključujući ponovno potvrđivanje otkazanog i pomicanje postojećeg termina.
- Školske ovlasti provjeravaju se prije traženja termina za mutacije;
  sigurnosni 401/403 vraćaju strukturirani JSON.
- Sve tri aplikacije čuvaju status, kod, poruku i putanju u `Failure`.
  Admin vidljivo prikazuje grešku obnove sesije, a kandidatska poruka isteka
  sesije više ne čeka iza prethodnog konfliktnog snackbara.
- Prolaze 25 backend testova na H2, 11 odabranih PostgreSQL regresija i backend
  paket. Svih 12 postojećih migracija primijenjeno je na prazni PostgreSQL 16.
- Prolazi 157 Flutter testova (admin 56, instruktor 58, kandidat 43), uz
  formatiranje i tri analize bez nalaza. Design system nije mijenjan ni ponovno
  testiran ovim zadatkom; gornji povijesni ukupni brojevi odnose se na raniji PR.
- [Opseg, ponovljive naredbe i ograničenja](../development/isolation-regressions.md).

## Preostali rad

1. Postupno implementirati prošireni Figma design system i ekrane kroz
   [GitHub Project](https://github.com/users/DarioJoske/projects/2). Postojeći
   Flutter paket s osnovnim komponentama još ne pokriva cijelu Figma biblioteku.
2. Dovršiti dodatne funkcionalnosti
   specificirane zasebnim zadacima.
3. Ručno proći povezani tijek: admin aktivira kandidata i dodijeli instruktora →
   kandidat zatraži termin → instruktor potvrdi i završi sat → svi vide novi zbroj.
4. Provjeriti mobilne buildove i ponašanje na stvarnim Android/iOS uređajima.
5. Pripremiti stabilno demo okruženje s HTTPS-om, izmišljenim podacima i računima
   za sve tri uloge te jednostavno vraćanje demo podataka.

## Ograničenja

- Pozivnice, samostalni oporavak lozinke, chat, push obavijesti, ispiti, plaćanja,
  dokumenti i napredna analitika ostaju zaseban planirani rad.
- Broj odrađenih sati nije procjena spremnosti za ispit.
- Povijesna migracija za procjene vještina i postojeći podaci ostaju sačuvani;
  trenutačni API i sučelja više ne nude unos tih procjena.
- Prije pilota treba urediti produkcijsko kreiranje škola, obnovu pristupa,
  sigurnosne kopije i probu vraćanja, nadzor te postupanje s osobnim podacima.
