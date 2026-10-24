# Gym – dziennik treningowy na iOS 6 (dawniej Siłka)

Aplikacja do zapisywania treningów na siłowni, napisana w Objective-C pod iOS 6 (jailbreak), budowana w Theosie na GitHubie.
Wygląd: grafit z połyskiem (odbicia na paskach, przyciskach i komórkach), 6 motywów kolorystycznych, 3 języki.

## Co potrafi (1.1)

* **Główna** – łączna liczba treningów, łączny czas i objętość (suma kg × powtórzenia ze wszystkich serii), liczba serii i powtórzeń,
  przyciski **Nowy trening** i **Powtórz poprzedni trening** oraz podsumowanie ostatniego treningu.
* **Trening** – start treningu, dodawanie ćwiczeń, serie z ciężarem i powtórzeniami, ptaszek „zrobione".
  Przy każdej serii podpowiada wartości z poprzedniego treningu tego ćwiczenia. Oznacza **nowe rekordy** (szacowane 1RM wg wzoru Epleya).
  „Powtórz ostatni trening" tworzy nowy trening z tych samych ćwiczeń.
* **Stoper przerwy** – po zaznaczeniu serii odlicza przerwę (domyślnie 90 s; -15/+15/Pomiń), wibruje i wysyła powiadomienie, gdy aplikacja jest w tle.
* **Historia** – lista treningów (czas, ćwiczenia, serie, objętość), podgląd, usuwanie przesunięciem, podsumowanie tygodnia.
* **Ćwiczenia** – ok. 110 popularnych ćwiczeń po polsku, angielsku i rosyjsku (wyszukiwarka działa po nazwach we wszystkich językach, partii mięśni i sprzęcie),
  własne ćwiczenia, statystyki i wykres szacowanego 1RM dla każdego.
* **Ustawienia** – **język** (automatycznie wg telefonu / polski / English / Русский), **motyw** (Grafit – pomarańcz, Błękit, Czerwień, Zieleń, Fiolet i jasne Srebro),
  kg/lb, długość przerwy, usunięcie danych. Język i motyw zmieniają się od razu, bez restartu; trwający trening i stoper przerwy zostają.

Dane są tylko w telefonie: `Documents/silka.json` (widoczne w iTunes → Udostępnianie plików, można zrobić kopię).

## Budowanie

1. Wgraj całą zawartość tego folderu do nowego publicznego repozytorium **Silka** na GitHubie (folder `.github` jest ukryty – w Finderze Cmd+Shift+.).
2. Settings → Actions → General → Workflow permissions → **Read and write permissions**.
3. Actions → **Zbuduj aplikację** → Run workflow (nie „Re-run all jobs"). Powstają `Silka.ipa` i `.deb`, które trafiają do wydania `najnowsza`.
4. Dopisz `slam0/Silka` do pliku `projekty.txt` w repozytorium `cydia` – pojawi się w Cydii.

Lokalnie: `./build.sh` (potrzebny Theos), test logiki: `gcc sl_core.c tests/core_test.c -lm && ./a.out`.

## Pliki

| Plik | Rola |
|---|---|
| `SLStore.*` | dane: ćwiczenia, treningi, historia, zapis JSON |
| `sl_core.*` | czysta logika w C (1RM, objętość, odmiana liczebników PL/EN/RU) + `tests/core_test.c` |
| `SLLang.*` | języki: tabela tłumaczeń `GL("polski napis")` (EN/RU), rzeczowniki z odmianą, ustawienie języka |
| `SLTheme.*`, `SLViews.*` | wygląd: tabela motywów i paleta, paski, żelowe przyciski, komórki, wykres, formatowanie liczb i dat |
| `SLHomeController.*` | zakładka Główna: łączne statystyki i przyciski startu |
| `SLWorkoutController.*` | zakładka Trening, serie, stoper przerwy |
| `SLPickerController.*`, `SLExercisesController.*` | lista ćwiczeń, wyszukiwarka, własne ćwiczenia, szczegóły i wykres |
| `SLHistoryController.*` | historia i podgląd treningu |
| `SLSettingsController.*` | ustawienia |
| `Resources/exercises.json` | wbudowana lista ćwiczeń (nazwy `name` PL, `en`, `ru`) |

## Dodawanie języka albo motywu

* Napisy w kodzie są po polsku i opakowane w `GL(@"…")`; tłumaczenie to jeden wiersz `{ PL, EN, RU }` w `SLLang.m`. Brak wiersza = napis zostaje po polsku.
* Motyw to jeden wiersz w tabeli `kThemes` w `SLTheme.m` (nazwa, kolor akcentu, ciemny/jasny); reszta palety liczy się z koloru akcentu.

## Źródła

Lista ćwiczeń powstała na podstawie nazw z projektu *free-exercise-db* (licencja Unlicense, domena publiczna).
Aplikacja nie korzysta z żadnych danych ani serwerów innych aplikacji treningowych.
