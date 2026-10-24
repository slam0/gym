# Siłka – dziennik treningowy na iOS 6

Aplikacja do zapisywania treningów na siłowni, napisana w Objective-C pod iOS 6 (jailbreak), budowana w Theosie na GitHubie.
Wygląd: grafit z połyskiem (odbicia na paskach, przyciskach i komórkach), pomarańczowy akcent.

## Co potrafi (1.0)

* **Trening** – start treningu, dodawanie ćwiczeń, serie z ciężarem i powtórzeniami, ptaszek „zrobione".
  Przy każdej serii podpowiada wartości z poprzedniego treningu tego ćwiczenia. Oznacza **nowe rekordy** (szacowane 1RM wg wzoru Epleya).
  „Powtórz ostatni trening" tworzy nowy trening z tych samych ćwiczeń.
* **Stoper przerwy** – po zaznaczeniu serii odlicza przerwę (domyślnie 90 s; -15/+15/Pomiń), wibruje i wysyła powiadomienie, gdy aplikacja jest w tle.
* **Historia** – lista treningów (czas, ćwiczenia, serie, objętość), podgląd, usuwanie przesunięciem, podsumowanie tygodnia.
* **Ćwiczenia** – ok. 110 popularnych ćwiczeń po polsku (wyszukiwarka także po angielsku, partii mięśni i sprzęcie),
  własne ćwiczenia, statystyki i wykres szacowanego 1RM dla każdego.
* **Ustawienia** – kg/lb, długość przerwy, usunięcie danych.

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
| `sl_core.*` | czysta logika w C (1RM, objętość, odmiana „seria/serie/serii") + `tests/core_test.c` |
| `SLTheme.*`, `SLViews.*` | wygląd: paski, żelowe przyciski, komórki, wykres |
| `SLWorkoutController.*` | zakładka Trening, serie, stoper przerwy |
| `SLPickerController.*`, `SLExercisesController.*` | lista ćwiczeń, wyszukiwarka, własne ćwiczenia, szczegóły i wykres |
| `SLHistoryController.*` | historia i podgląd treningu |
| `SLSettingsController.*` | ustawienia |
| `Resources/exercises.json` | wbudowana lista ćwiczeń (polskie nazwy własne) |

## Źródła

Lista ćwiczeń powstała na podstawie nazw z projektu *free-exercise-db* (licencja Unlicense, domena publiczna).
Aplikacja nie korzysta z żadnych danych ani serwerów innych aplikacji treningowych.
