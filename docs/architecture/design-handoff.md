# Figma → implementacija: termini, sati i pristup

Datum: 2026-09-17. Zadatak: [#2](https://github.com/DarioJoske/auto-skola-365/issues/2).
Uspoređeni su kod na commitu `0f2aba8` i
[Figma blueprint 1.0, handoff 49:67](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=49-67).

Ovaj dokument bilježi postojeća pravila za sljedeće implementacijske zadatke.
Primjeri iz maketa ne mijenjaju poslovnu logiku. Vrijede
[produktna specifikacija](../product/mvp-product-spec.md),
[API ugovori](api.md) i [Flutter arhitektura](flutter-architecture.md).
Promjena trajanja ili obračuna traži zasebnu potvrđenu produktnu odluku i
opis učinka na postojeće termine i evidenciju. Ovim zadatkom takva promjena
nije uvedena.

Dopuna 2026-09-25: [task #10](../development/request-availability.md) uvodi
prijedlog s obveznim odgovorom kandidata i provedbu dostupnosti. Pravila ispod
ažurirana su za taj tok.

## Odluke i odstupanja od maketa

| Područje / Figma izvor | Pravilo za aktualnu implementaciju |
| --- | --- |
| [A03 · Novi termin](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=31-263): 90 min / 2 školska sata | Fiksnih 60 minuta u kalendaru; jedan odgovarajući završeni termin daje jedan nastavni sat. Trajanje nije izbor. |
| [C04 · Zatraži vožnju](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=25-236) i C04-R: 45 min; [C06 · Detalj termina](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=25-376): 16:30–18:00 / 2 sata | Prikazati 60 minuta rezerviranog vremena, npr. 16:30–17:30. Nastavnih 45 minuta unutar tog termina nije trajanje kalendarske rezervacije. |
| [I04 · Završi sat](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-844): unos statusa, 2 sata i teme | Akcija završava postojeći potvrđeni termin; broj sati se ne unosi. API prihvaća samo neobavezni `note`; zasebno polje teme nije podržano. |
| I04 i [I11 · Sat je evidentiran](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=43-564): bilješka vidljiva Ani, +2 sata | Bilješka ostaje interna. Nakon uspjeha učitati zbroj s backenda; za odgovarajuću aktualnu kategoriju jedna vožnja daje +1. Ne obećavati +1 za povijesnu kategoriju. |
| [A06 · Upis kandidata](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=33-1682) i [S01 · Prijava](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=39-45): pozivnica i oporavak lozinke | Aktivacija početnom lozinkom kroz admin spremanje kandidata. Pozivnice i samostalni oporavak ostaju budući rad. |
| [C05 · Zahtjev je poslan](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=25-306): povlačenje; C06: zahtjev za promjenu; [I07 · Zahtjev termina](https://www.figma.com/design/PYieT0HT4rpSslsWaH9iWc?node-id=26-1057): potvrda i obavijest | Kandidat šalje zahtjev te prihvaća ili odbija prijedlog drugog vremena. Instruktor potvrđuje, odbija ili predlaže. Odbijanje se mapira na `CANCELLED`. Obavijesti nisu implementirane. |

Figma handoff sažima ove odluke. Ostali ekrani ostaju ilustrativni blueprint;
gornja tablica definira obvezne prilagodbe pri implementaciji tih ekrana.

## Trajanje i izvor evidencije

- API prihvaća samo `DRIVING` i točno 60 minuta. Ako `endAt` nije poslan,
  backend računa `startAt + 60 min`; druga vrijednost završetka vraća `400`.
- `completedDrivingHours` je broj zapisa sa statusom `COMPLETED` i tipom
  `DRIVING` za istog kandidata, školu i kandidatovu **aktualnu kategoriju**.
  Upit broji zapise, ne dijeli ukupne minute s 45 ili 60. Promjena kategorije
  mijenja skup vožnji koje ulaze u zbroj; povijest ostaje sačuvana.
- `REQUESTED`, `CONFIRMED`, `CANCELLED` i `NO_SHOW` daju nula sati.
  Istek termina i prikaz u povijesti nisu dokaz završetka.
- Cilj je `requiredDrivingHours`: zadano 35 za B, bez pretpostavljenog cilja
  za ostale kategorije. Admin može postaviti pozitivan individualni cilj.
  Stvarni zbroj ostaje vidljiv i iznad cilja, npr. `37/35`.
- Dosegnuti cilj ne mijenja automatski status kandidata ili spremnost za ispit.
  UI prikazuje backend zbroj i nakon uspješne mutacije ga ponovno dohvaća.

Primjer: pri `25/35`, potvrđena vožnja 16:30–17:30 ostavlja zbroj na 25.
Nakon dopuštenog završavanja backend vraća 26, ako vožnja pripada aktualnoj
kategoriji. Ponovni pokušaj završavanja vraća `409` i ne povećava zbroj.

## Statusi i prijelazi

Oznake za nove ekrane: `REQUESTED` → „Čeka potvrdu”, `CONFIRMED` → „Potvrđeno”,
`COMPLETED` → „Odrađeno”, `CANCELLED` → „Otkazano”, `NO_SHOW` → „Nedolazak”.
„Održano” i „Završeno” iz maketa nisu dodatni API statusi. Nema `MOVED`,
`REJECTED` ni zasebnih statusa otkazivanja po ulozi.

Tablica opisuje **stvarno dopuštene API prijelaze**, uključujući one koje
trenutačni instruktor UI ne nudi:

| Radnja | Polazno stanje | Rezultat | Ovlasti i provjere |
| --- | --- | --- | --- |
| Kandidat šalje zahtjev | Novi zapis | `REQUESTED` | `lessons.reserve_own`, povezani kandidat iz JWT-a, trenutačno dodijeljeni aktivni instruktor i odgovarajuća kategorija. |
| Instruktor rezervira | Novi zapis | `CONFIRMED` | `lessons.view_assigned`, aktivni instruktor iz prijave, njegov trenutačno dodijeljeni kandidat; početak mora biti u budućnosti. |
| Opći create | Novi zapis | `REQUESTED` (zadano), `CONFIRMED` ili `CANCELLED` | `lessons.manage` ili ovlašteni instruktor naveden na terminu; provjera aktualne dodjele i trajanja. |
| Confirm | `REQUESTED`, `CONFIRMED`, `CANCELLED` | `CONFIRMED` | `lessons.manage` ili ovlašteni instruktor zapisan na terminu; ponovna provjera dodjele, članstva, dostupnosti i preklapanja; za kandidatski zahtjev samo `REQUESTED`, bez prijedloga na čekanju. |
| Cancel | `REQUESTED`, `CONFIRMED`, `CANCELLED` | `CANCELLED` | `lessons.manage` ili ovlašteni instruktor zapisan na terminu. |
| Opći update / pomicanje | `REQUESTED`, `CONFIRMED`, `CANCELLED` | `REQUESTED`, `CONFIRMED` ili `CANCELLED` | `lessons.manage`; ponovno provjerava aktualnu dodjelu, trajanje, dostupnost i preklapanja; prijedlog na čekanju dopušta samo otkazivanje. |
| Complete | Samo `CONFIRMED` | `COMPLETED` | Aktivni instruktor zapisan na terminu, `lessons.view_assigned`, `endAt <=` vrijeme servera. Admin dozvola sama nije dovoljna. |
| Promjena konačnog zapisa | `COMPLETED`, `NO_SHOW` | `409` pri confirm/cancel/complete; update s inače valjanim podacima također je odbijen | Konačni zapisi se ne uređuju, potvrđuju niti otkazuju. |

Izravni create/update na `COMPLETED` ili `NO_SHOW` vraća `400`. `NO_SHOW`
postoji u modelu, filtrima i prikazu, ali nema implementiranu radnju upisa.
Instruktor UI nudi potvrdu samo za `REQUESTED`, a otkazivanje za `REQUESTED`
i `CONFIRMED`. Za nekandidatske zapise API dopušta ponovljeni confirm/cancel i ponovno
potvrđivanje otkazanog termina. Kandidatski confirm zahtijeva `REQUESTED`;
prijedlog na čekanju blokira confirm i update osim izričitog otkazivanja.
Prihvaćanje/odbijanje prijedloga ima strogu provjeru statusa i očekivanog vremena.

Svi statusi osim `CANCELLED` blokiraju preklapanje kandidata i instruktora,
uključujući zahtjev koji još nije potvrđen. Susjedni termini bez preklapanja
su dopušteni. Sukob vraća `409`. Confirm mijenja isti termin, ne stvara drugu
vožnju. `COMPLETED` i serverski `completedAt` određuju završetak; `confirmedAt`
ne mora biti popunjen pri izravnom kreiranju potvrđenog termina.

Update/confirm/cancel/complete zaključavaju redak za vrijeme transakcije.
Ponovno ili konkurentno završavanje ne smije ponovno evidentirati vožnju.

## Dodjela i autorizacija

- Aktivno članstvo u traženoj školi i dozvole provjerava backend.
  Vrijednosti koje frontend šalje nisu dokaz ovlasti.
- Kandidat u zahtjevu ne odabire svoj identitet, instruktora, tip ni status.
  Instruktor u vlastitoj rezervaciji ne odabire identitet instruktora.
- Admin prvo bira instruktora pa kandidata iz njegova aktualnog popisa;
  promjena instruktora resetira odabir kandidata. API ponovno provjerava dodjelu.
- Završavanje provjerava instruktora **zapisanog na terminu**. Provjera aktualne
  dodjele kandidata primjenjuje se na nove/izmijenjene rezervacije i instruktorov
  pregled napretka. To nisu identične provjere nakon promjene instruktora.
- Kandidat može odgovoriti na prijedlog vlastitog zahtjeva. Nema opću ovlast
  potvrđivanja, završavanja, povlačenja ili otkazivanja drugih termina.

Budući početak provjeravaju instruktorova i kandidatska rezervacija, prijedlog
i njegovo prihvaćanje. Opći administrativni create/update zadržavaju mogućnost
unosa povijesnih termina. Dostupnost se provjerava na svim putanjama upisa.

## Javne i interne bilješke

| Podatak | Trenutačna namjena | Kandidatski portal |
| --- | --- | --- |
| `Candidate.notes` | Interna napomena o kandidatu | Polje se ne vraća. |
| `Lesson.notes` | Operativna napomena škole/instruktora ili kandidatova poruka uz zahtjev | Polje se ne vraća. |
| `Lesson.completionNote` | Interna bilješka instruktora nakon vožnje, do 2000 znakova | Polje se ne vraća. |
| Buduća javna povratna informacija | Zasebno polje i eksplicitna pravila vidljivosti tek nakon nove specifikacije | Još ne postoji. |

`GET /candidate-portal` koristi ograničeni DTO s vlastitim terminima i zbrojem,
bez svih navedenih bilješki. Kandidatova poruka pri rezervaciji ne daje pravo
čitanja kasnijih internih napomena. Odgovor na kreiranje zahtjeva trenutačno
koristi opći `LessonResponse` s vlastitim poslanim `notes` i praznim
`completionNote`; to nije endpoint za čitanje internih bilješki postojećeg sata.
Ne zamjenjivati portal općim školskim endpointom za detalj termina.

Za I04 koristiti „Interna bilješka (neobavezno)” i objašnjenje „Bilješka je
vidljiva samo ovlaštenom osoblju škole.” Ne mapirati „Bilješka kandidatu” iz
makete na postojeći `completionNote`. Buduća javna bilješka ne smije automatski
preuzeti povijesni sadržaj internih polja.

## Aktivacija računa i budući pristup

Aktualni tijek: admin spremi kandidata s kontaktnim emailom koji nije zauzet i
`loginPassword` od 8–72 znakova → backend stvori i poveže novi račun i
kandidatsko članstvo → kandidat se prijavi tim emailom i lozinkom.

- Bez `loginPassword` zapis kandidata može postojati bez korisničkog računa.
- Prazno polje u admin UI-ju šalje `null` i ne mijenja postojeću lozinku.
- Račun se nikad ne preuzima podudaranjem email adrese. Promjena kontaktnog
  emaila ne mijenja `loginEmail`; UI prikazuje razliku.
- Admin može promijeniti lozinku već povezanog računa samo uz aktivno
  kandidatsko članstvo te škole i bez drugog članstva škole ili druge uloge.
- Nema slanja pozivnica/emaila, tokena za prihvat poziva, samostalnog oporavka
  niti prisilne promjene početne lozinke pri prvoj prijavi.

A06 treba koristiti „Spremi” i polje početne lozinke, bez poruke da je pozivnica
poslana. S01 treba objasniti da pristupne podatke daje autoškola, a za obnovu
pristupa uputiti na školu. Ne nuditi aktivnu poveznicu na nepostojeći oporavak.
Pozivnice i oporavak ostaju zasebni budući tokovi s vlastitim API ugovorima.

## Primjena i provjera

| Kriterij zadatka #2 | Odluka za predaju |
| --- | --- |
| 60 min nasuprot 90 min / 2 sata | Ostaje 60 min / 1 sat; odstupanja popisana po ekranima. |
| Zahtjev, potvrda, završetak i fond | Tablica stvarnih prijelaza i backend filtera iznad. |
| Javna i interna bilješka | Postojeće bilješke ostaju interne; javno polje je budući rad. |
| Izvor sati, dodjela, vrijeme završetka | Backend zbroj, provjere identiteta i dodjele, serverski kraj termina. |
| Aktivacija nasuprot pozivnicama i oporavku | Početna lozinka sada; zasebni budući tokovi. |

Izvori provjereni u kodu:

- [LessonService](../../backend/src/main/java/com/autoskola365/backend/lesson/LessonService.java),
  [Lesson](../../backend/src/main/java/com/autoskola365/backend/lesson/Lesson.java) i
  [LessonRepository](../../backend/src/main/java/com/autoskola365/backend/lesson/LessonRepository.java):
  trajanje, ovlasti, prijelazi i zaključavanje.
- [ProgressService](../../backend/src/main/java/com/autoskola365/backend/progress/ProgressService.java) i
  [CandidatePortalService](../../backend/src/main/java/com/autoskola365/backend/candidate/CandidatePortalService.java):
  aktualna kategorija, škola, zbroj i ograničeni kandidatski DTO.
- [CandidateService](../../backend/src/main/java/com/autoskola365/backend/candidate/CandidateService.java):
  povezivanje računa, početna lozinka i odvojen prijavni email.
- [LessonCompletionTest](../../backend/src/test/java/com/autoskola365/backend/lesson/LessonCompletionTest.java) i
  [AuthFlowIntegrationTest](../../backend/src/test/java/com/autoskola365/backend/auth/AuthFlowIntegrationTest.java):
  postojeći primjeri provjera završavanja, konkurentnih zahtjeva, zbroja,
  aktivacije i izostavljanja internih bilješki iz portala.

Ovo je dokumentacijski zadatak: provjeriti dosljednost navedenih pravila,
lokalne poveznice i `git diff --check`. Čitanje postojećih testova nije njihovo
ponovno pokretanje. Buduće promjene ponašanja moraju pokrenuti provjere prema
[AGENTS.md](../../AGENTS.md), uključujući testove autorizacije i vidljivosti bilješki.
