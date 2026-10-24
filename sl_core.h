/* Proste obliczenia treningowe w czystym C (bez libm), osobno, żeby dało się je przetestować. */
#ifndef SL_CORE_H
#define SL_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

/* Szacowany ciężar na jedno powtórzenie (wzór Epleya): kg * (1 + powtórzenia / 30). */
double sl_e1rm(double kg, int reps);
/* Objętość serii = kg * powtórzenia. */
double sl_volume(double kg, int reps);
double sl_kg_to_lb(double kg);
double sl_lb_to_kg(double lb);
/* Zaokrągla do 0,01 (bez libm). */
double sl_round2(double v);
/* Polska odmiana: 0 = 1 (seria), 1 = 2-4 (serie), 2 = reszta (serii). */
int sl_plural_pl(long n);
/* Odmiana w trzech językach: lang 0 = polski, 1 = angielski, 2 = rosyjski.
   Zwraca 0 = forma pojedyncza, 1 = "kilka" (pl 2-4, ru 2-4), 2 = reszta. Angielski: 0 albo 2. */
int sl_plural(int lang, long n);
/* Rozbija sekundy na godziny, minuty i sekundy. */
void sl_split_seconds(long total, long *h, long *m, long *s);

#ifdef __cplusplus
}
#endif
#endif
