#include "sl_core.h"

double sl_e1rm(double kg, int reps)
{
    if (kg <= 0.0 || reps <= 0) return 0.0;
    if (reps == 1) return kg;
    return kg * (1.0 + (double)reps / 30.0);
}

double sl_volume(double kg, int reps)
{
    if (kg < 0.0 || reps < 0) return 0.0;
    return kg * (double)reps;
}

double sl_kg_to_lb(double kg) { return kg / 0.45359237; }
double sl_lb_to_kg(double lb) { return lb * 0.45359237; }

double sl_round2(double v)
{
    long scaled;
    if (v >= 0.0) scaled = (long)(v * 100.0 + 0.5);
    else          scaled = -(long)(-v * 100.0 + 0.5);
    return (double)scaled / 100.0;
}

int sl_plural_pl(long n)
{
    long a, b;
    if (n < 0) n = -n;
    if (n == 1) return 0;
    a = n % 10;
    b = n % 100;
    if (a >= 2 && a <= 4 && !(b >= 12 && b <= 14)) return 1;
    return 2;
}

void sl_split_seconds(long total, long *h, long *m, long *s)
{
    if (total < 0) total = 0;
    *h = total / 3600;
    *m = (total % 3600) / 60;
    *s = total % 60;
}
