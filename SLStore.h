#import <Foundation/Foundation.h>

/* Wszystkie dane aplikacji w jednym pliku Documents/silka.json.
   Trening to słownik: id, start, end, entries[ { ex, sets[ { kg, reps, done } ] } ]. */

extern NSString *const SLStoreDidChangeNotification;

@interface SLStore : NSObject

+ (SLStore *)shared;

/* ---- ćwiczenia ---- */
- (NSArray *)allExercises;                              /* [{id,name,en,muscle,equip,custom}] posortowane po nazwie */
- (NSDictionary *)exerciseForId:(NSString *)exId;
- (NSString *)nameForExerciseId:(NSString *)exId;
- (NSString *)addCustomExerciseNamed:(NSString *)name muscle:(NSString *)muscle;
- (NSArray *)muscleGroups;                              /* kolejność wyświetlania */

/* ---- trening w toku ---- */
- (NSMutableDictionary *)active;                        /* nil, gdy nie ma */
- (void)startWorkout;
- (void)startWorkoutRepeating:(NSDictionary *)workout;  /* te same ćwiczenia, puste serie z poprzednimi wartościami */
- (void)addExercise:(NSString *)exId toWorkout:(NSMutableDictionary *)w;
- (void)removeEntryAtIndex:(NSUInteger)i fromWorkout:(NSMutableDictionary *)w;
- (void)addSetToEntry:(NSMutableDictionary *)entry;     /* kopiuje wartości z ostatniej serii */
- (BOOL)activeHasDoneSets;
- (BOOL)finishActive;                                   /* przenosi do historii; NO gdy brak wykonanych serii */
- (void)discardActive;

/* ---- historia ---- */
- (NSArray *)workouts;                                  /* ukończone, najnowsze pierwsze */
- (void)deleteWorkoutWithId:(NSString *)wid;
/* Dla ćwiczenia: [{date(double), wid, sets:[{kg,reps}]}] od najnowszego; tylko wykonane serie. */
- (NSArray *)historyForExercise:(NSString *)exId;
/* Ostatnia wykonana seria tego ćwiczenia przed obecnym treningiem (do podpowiedzi). */
- (NSDictionary *)lastSetsInfoForExercise:(NSString *)exId excludingWorkout:(NSDictionary *)w;
- (double)bestE1RMForExercise:(NSString *)exId excludingWorkout:(NSDictionary *)w;

/* ---- statystyki treningu ---- */
+ (double)volumeOfWorkout:(NSDictionary *)w;
+ (NSInteger)doneSetsInWorkout:(NSDictionary *)w;
+ (NSInteger)exerciseCountInWorkout:(NSDictionary *)w;
+ (double)durationOfWorkout:(NSDictionary *)w;
/* Suma ze wszystkich zakończonych treningów: count, seconds, volume (kg), sets, reps */
- (NSDictionary *)totalStats;

/* ---- ustawienia ---- */
@property (nonatomic) NSInteger units;                  /* 0 = kg, 1 = lb */
@property (nonatomic) NSInteger restSeconds;            /* 0 = bez stopera */

- (void)save;
- (void)clearAll;
- (NSString *)newId:(NSString *)prefix;

@end
