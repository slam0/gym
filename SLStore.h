#import <UIKit/UIKit.h>

/* Wszystkie dane aplikacji w jednym pliku Documents/silka.json.
   Trening to słownik: id, start, end, entries[ { ex, sets[ { kg, reps, done } ] } ]. */

extern NSString *const SLStoreDidChangeNotification;

@interface SLStore : NSObject

+ (SLStore *)shared;

/* ---- ćwiczenia ---- */
- (NSArray *)allExercises;                              /* [{id,name,en,muscle,equip,custom}] posortowane po nazwie */
- (NSDictionary *)exerciseForId:(NSString *)exId;
- (NSString *)nameForExerciseId:(NSString *)exId;        /* w wybranym języku */
- (NSString *)displayNameForExercise:(NSDictionary *)ex;
- (NSString *)searchTextForExercise:(NSDictionary *)ex;  /* nazwy we wszystkich językach + partia + sprzęt */
- (void)invalidateExerciseCache;                        /* po zmianie języka (zmienia się kolejność) */
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

/* ---- plany (szablony treningów) ----
   Plan to słownik: id, name, ex (tablica id ćwiczeń). */
- (NSArray *)plans;
- (NSMutableDictionary *)addPlanNamed:(NSString *)name exercises:(NSArray *)exIds;
- (void)deletePlanWithId:(NSString *)pid;
/* Nowy trening z listy ćwiczeń: serie jak ostatnio, a gdy brak historii, tyle pustych serii, ile w setsIfNew. */
- (void)startWorkoutFromExerciseIds:(NSArray *)exIds defaultSets:(NSInteger)setsIfNew;

/* ---- pomiary ciała ----
   typ: 0 waga (kg), 1 biceps, 2 klatka, 3 talia, 4 biodra, 5 udo (cm). Wpis: id, t, v, d (czas). */
- (NSArray *)measuresOfType:(NSInteger)type;            /* najnowsze pierwsze */
- (void)addMeasure:(double)value type:(NSInteger)type;
- (void)deleteMeasureWithId:(NSString *)mid;

/* ---- zdjęcia postępów (pliki w Documents/progress) ---- */
- (NSArray *)photos;                                    /* [{id,d}] najnowsze pierwsze */
- (NSString *)addPhotoWithImage:(UIImage *)image;        /* zmniejsza i zapisuje; zwraca id albo nil */
- (void)deletePhotoWithId:(NSString *)pid;
- (NSString *)photoPathForId:(NSString *)pid thumb:(BOOL)thumb;

/* ---- ustawienia ---- */
@property (nonatomic) NSInteger units;                  /* 0 = kg, 1 = lb */
@property (nonatomic) NSInteger restSeconds;            /* 0 = bez stopera */
@property (nonatomic) NSInteger languageSetting;        /* 0 auto, 1 pl, 2 en, 3 ru */
@property (nonatomic) NSInteger themeIndex;             /* numer motywu */

- (void)save;
- (void)clearAll;
- (NSString *)newId:(NSString *)prefix;

@end
