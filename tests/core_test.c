#include <stdio.h>
#include <math.h>
#include "../sl_core.h"

static int fails = 0;
#define CHECK(c) do { if (!(c)) { printf("BLAD (linia %d): %s\n", __LINE__, #c); fails++; } } while (0)
static int near(double a, double b) { return fabs(a - b) < 0.0001; }

int main(void)
{
    CHECK(near(sl_e1rm(100, 1), 100));
    CHECK(near(sl_e1rm(100, 10), 133.3333333));
    CHECK(near(sl_e1rm(60, 8), 76.0));
    CHECK(near(sl_e1rm(0, 8), 0));
    CHECK(near(sl_e1rm(50, 0), 0));
    CHECK(near(sl_volume(60, 8), 480));
    CHECK(near(sl_volume(-1, 8), 0));
    CHECK(near(sl_kg_to_lb(45.359237), 100));
    CHECK(near(sl_lb_to_kg(100), 45.359237));
    CHECK(near(sl_round2(62.504), 62.5));
    CHECK(near(sl_round2(62.505), 62.51));
    CHECK(near(sl_round2(-1.234), -1.23));
    CHECK(sl_plural_pl(1) == 0);
    CHECK(sl_plural_pl(2) == 1 && sl_plural_pl(3) == 1 && sl_plural_pl(4) == 1);
    CHECK(sl_plural_pl(5) == 2 && sl_plural_pl(0) == 2 && sl_plural_pl(11) == 2);
    CHECK(sl_plural_pl(12) == 2 && sl_plural_pl(14) == 2 && sl_plural_pl(22) == 1);
    CHECK(sl_plural_pl(112) == 2 && sl_plural_pl(21) == 2 && sl_plural_pl(101) == 2);
    /* angielski */
    CHECK(sl_plural(1, 1) == 0 && sl_plural(1, 0) == 2 && sl_plural(1, 2) == 2 && sl_plural(1, 21) == 2);
    /* rosyjski: 1 подход, 2-4 подхода, 5+ подходов, 11 подходов, 21 подход, 22 подхода, 111 подходов */
    CHECK(sl_plural(2, 1) == 0 && sl_plural(2, 21) == 0 && sl_plural(2, 101) == 0);
    CHECK(sl_plural(2, 2) == 1 && sl_plural(2, 4) == 1 && sl_plural(2, 22) == 1 && sl_plural(2, 104) == 1);
    CHECK(sl_plural(2, 0) == 2 && sl_plural(2, 5) == 2 && sl_plural(2, 11) == 2 && sl_plural(2, 12) == 2);
    CHECK(sl_plural(2, 14) == 2 && sl_plural(2, 111) == 2 && sl_plural(2, 20) == 2 && sl_plural(2, 25) == 2);
    /* polski przez wspólną funkcję */
    CHECK(sl_plural(0, 1) == 0 && sl_plural(0, 3) == 1 && sl_plural(0, 5) == 2 && sl_plural(0, 22) == 1 && sl_plural(0, 21) == 2);
    long h, m, s;
    sl_split_seconds(3725, &h, &m, &s);
    CHECK(h == 1 && m == 2 && s == 5);
    sl_split_seconds(-5, &h, &m, &s);
    CHECK(h == 0 && m == 0 && s == 0);
    if (fails == 0) printf("OK: wszystkie testy logiki przeszly\n");
    return fails ? 1 : 0;
}
