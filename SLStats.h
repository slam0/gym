#import <Foundation/Foundation.h>

/* Analiza historii treningów: rekordy, tygodnie, serie tygodni, partie mięśni, dni z treningiem. */
@interface SLStats : NSObject

/* początek tygodnia (poniedziałek 00:00); weeksAgo = 0 to bieżący tydzień */
+ (NSTimeInterval)weekStartWeeksAgo:(NSInteger)weeksAgo;

/* Liczba treningów w każdym z ostatnich n tygodni, od najstarszego do bieżącego. */
+ (NSArray *)weeklyCounts:(NSInteger)n;
/* Objętość (kg) w każdym z ostatnich n tygodni, od najstarszego do bieżącego. */
+ (NSArray *)weeklyVolumes:(NSInteger)n;
/* Ile tygodni z rzędu (licząc wstecz od bieżącego albo poprzedniego) był choć jeden trening. */
+ (NSInteger)weekStreak;
+ (NSInteger)workoutsSince:(NSTimeInterval)ts;

/* Rekordy: dla każdego ćwiczenia z historią słownik
   ex, kg (największy ciężar), e1rm, vol (najlepsza seria kg*powt.), kgReps (powt. przy największym ciężarze),
   date (data rekordu 1RM). Posortowane od najwyższego szacowanego 1RM. */
+ (NSArray *)records;
/* Ile ćwiczeń ma rekord 1RM ustanowiony po ts. */
+ (NSInteger)recordsSince:(NSTimeInterval)ts;
/* Ile ćwiczeń w tym treningu pobiło rekord (serie oznaczone "pr"). */
+ (NSInteger)recordCountInWorkout:(NSDictionary *)w;

/* Wykonane serie po partiach mięśni od ts (0 = od początku): słownik partia -> NSNumber. */
+ (NSDictionary *)setsByMuscleSince:(NSTimeInterval)ts;

/* Treningi pogrupowane po dniach: klucz rok*10000 + miesiąc*100 + dzień -> tablica treningów. */
+ (NSDictionary *)workoutsByDay;
+ (NSInteger)dayKeyForDate:(NSDate *)d;

@end
