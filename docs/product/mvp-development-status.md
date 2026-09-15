# MVP — stanje razvoja i nastavak

Ažurirano: 2026-09-15. Razvoj je zaustavljen na zahtjev korisnika nakon koraka 3.
Pri nastavku odraditi samo jedan korak, stati i dati kratki review korisniku.
Ne prelaziti automatski na sljedeći korak.

## Dovršeno u kodu

- Instruktorski raspored, detalji termina, potvrda i otkazivanje te popis dodijeljenih kandidata.
- Stabilizacija učitavanja: zaštita od zakašnjelih odgovora i odgovora nakon zatvaranja ekrana.
- Zaštita od ponovljenih radnji i ažuriranje filtriranog rasporeda nakon promjene statusa.
- Korak 2: završavanje vlastitog potvrđenog sata nakon isteka termina, neobavezna bilješka i vrijeme evidentiranja.
- Završeni sat zaštićen je od ponovnog završavanja, uređivanja i otkazivanja.
- Korak 3: deset vještina B kategorije, pet razina procjene, unos/ispravak procjena uz odrađeni sat.
- Instruktorski pregled posljednjih procjena i povijesti po satima.
- Redoslijed napretka određuje datum sata, a ne vrijeme naknadnog ispravka.
- Backend ovlasti, API dokumentacija i regresijski testovi za navedene funkcionalnosti.

Posljednje uspješne provjere: 15 Flutter testova instruktorske aplikacije,
13 backend testova, analiza admin i instruktorske aplikacije te backend package.
Backend testovi koriste H2 i ne pokreću Flyway migracije.

## Prvi sljedeći korak

- [ ] Admin profil kandidata: prikaz posljednjih procjena po vještinama i povijesti sati.
- [ ] Prikaz odrađenih sati, bilješki nakon vožnje i instruktorskih procjena u profilu.
- [ ] Povezati s postojećim API-jem za napredak; uvesti potrebne admin domenske modele,
      repozitorije, use caseove i Cubit, uz postojeća arhitekturna pravila.
- [ ] Testirati, stati i dati kratak review.

## Preostalo do prezentacijskog MVP-a

1. Početni pregled s pravim podacima: današnji termini, aktivni kandidati i termini za potvrdu.
2. Proći osnovne admin tijekove: upis/uređivanje/pretraga kandidata, dodjela instruktora,
   upravljanje instruktorima te kreiranje i premještanje termina uz zabranu preklapanja.
3. Doraditi sučelja: hrvatski nazivi i dijakritika, prikaz datuma/vremena, validacija,
   prazna stanja, učitavanje, pogreške i osvježavanje nakon promjena.
4. Provjeriti korištenje admin aplikacije na računalu i instruktorske na mobitelu.
5. Proći cijeli tijek kroz oba sučelja: admin zakazuje → instruktor završava sat i
   procjenjuje vještine → admin vidi rezultat.
6. Potvrditi odvajanje škola i ovlasti, istek prijave, nedostupan backend, trajnost podataka
   nakon osvježavanja/ponovne prijave te konflikte pri kreiranju i premještanju termina.
7. Pripremiti stabilno demo okruženje s HTTPS-om, izmišljenim podacima, odvojenim računima
   admina/instruktora i jednostavnim vraćanjem demo podataka.
8. Pripremiti desetominutni demo scenarij, termine za dan prezentacije i rezervnu snimku.

## Neprovjereno / ograničenja

- [ ] Primijeniti i provjeriti V10__lesson_completion.sql i V11__lesson_progress.sql na PostgreSQL-u.
      Migracije se primjenjuju pri pokretanju novog backenda; nisu potvrđene ovim testovima.
- [ ] Ručno provjeriti cijeli tijek u aplikacijama povezanima na backend.
- Predložak napretka trenutačno podržava samo B kategoriju.
- Povijest procjena je po satima; ispravci iste procjene nemaju zaseban audit zapis.
- Prikaz napretka u admin aplikaciji još nije implementiran.

## Izvan prvog prezentacijskog MVP-a

Kandidatska aplikacija, chat, push obavijesti, plaćanja, dokumenti, napredna analitika
te puni SuperAdmin mogu pričekati. Za demo je dovoljno kontrolirano kreiranje škole
s početnim računima.

Prije pilota sa stvarnom autoškolom dodatno pripremiti obnovu pristupa, upravljanje
korisnicima, sigurnosne kopije i probu vraćanja, nadzor pogrešaka te pravila
postupanja s osobnim podacima.
