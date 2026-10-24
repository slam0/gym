#import "SLStore.h"
#import "sl_core.h"

NSString *const SLStoreDidChangeNotification = @"SLStoreDidChangeNotification";

@interface SLStore ()
{
    NSMutableDictionary *_root;
    NSArray *_builtin;
    NSMutableDictionary *_byId;
    NSArray *_all;                  /* cache wszystkich ćwiczeń */
}
@end

@implementation SLStore

+ (SLStore *)shared
{
    static SLStore *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[SLStore alloc] init]; });
    return s;
}

- (NSString *)dataPath
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[dirs objectAtIndex:0] stringByAppendingPathComponent:@"silka.json"];
}

- (id)init
{
    if ((self = [super init])) {
        [self load];
        [self loadBuiltin];
    }
    return self;
}

- (void)load
{
    NSData *d = [NSData dataWithContentsOfFile:[self dataPath]];
    id obj = nil;
    if (d) {
        obj = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingMutableContainers error:NULL];
        if (![obj isKindOfClass:[NSMutableDictionary class]]) {
            /* uszkodzony plik: zachowaj kopię i zacznij od zera */
            NSString *bad = [[self dataPath] stringByAppendingString:@".uszkodzony"];
            [[NSFileManager defaultManager] removeItemAtPath:bad error:NULL];
            [[NSFileManager defaultManager] moveItemAtPath:[self dataPath] toPath:bad error:NULL];
            obj = nil;
        }
    }
    _root = obj ? obj : [NSMutableDictionary dictionary];
    if (![[_root objectForKey:@"workouts"] isKindOfClass:[NSMutableArray class]]) [_root setObject:[NSMutableArray array] forKey:@"workouts"];
    if (![[_root objectForKey:@"custom"] isKindOfClass:[NSMutableArray class]]) [_root setObject:[NSMutableArray array] forKey:@"custom"];
    if (![[_root objectForKey:@"seq"] isKindOfClass:[NSNumber class]]) [_root setObject:[NSNumber numberWithInt:1] forKey:@"seq"];
    if ([[_root objectForKey:@"active"] isKindOfClass:[NSNull class]]) [_root removeObjectForKey:@"active"];
}

- (void)loadBuiltin
{
    NSString *p = [[NSBundle mainBundle] pathForResource:@"exercises" ofType:@"json"];
    NSData *d = p ? [NSData dataWithContentsOfFile:p] : nil;
    id obj = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:NULL] : nil;
    _builtin = [obj isKindOfClass:[NSArray class]] ? obj : [NSArray array];
}

- (void)save
{
    NSData *d = [NSJSONSerialization dataWithJSONObject:_root options:0 error:NULL];
    if (d) [d writeToFile:[self dataPath] atomically:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:SLStoreDidChangeNotification object:self];
}

- (NSString *)newId:(NSString *)prefix
{
    int n = [[_root objectForKey:@"seq"] intValue];
    [_root setObject:[NSNumber numberWithInt:n + 1] forKey:@"seq"];
    return [NSString stringWithFormat:@"%@%d_%ld", prefix, n, (long)[[NSDate date] timeIntervalSince1970]];
}

/* ---------- ustawienia ---------- */

- (NSInteger)units { return [[_root objectForKey:@"units"] integerValue]; }
- (void)setUnits:(NSInteger)u { [_root setObject:[NSNumber numberWithInteger:u] forKey:@"units"]; [self save]; }
- (NSInteger)restSeconds
{
    NSNumber *n = [_root objectForKey:@"rest"];
    return n ? [n integerValue] : 90;
}
- (void)setRestSeconds:(NSInteger)s { [_root setObject:[NSNumber numberWithInteger:s] forKey:@"rest"]; [self save]; }

/* ---------- ćwiczenia ---------- */

- (NSArray *)muscleGroups
{
    return [NSArray arrayWithObjects:@"Klatka piersiowa", @"Plecy", @"Barki", @"Biceps", @"Triceps", @"Przedramiona",
            @"Brzuch", @"Uda (przód)", @"Uda (tył)", @"Pośladki", @"Łydki", @"Cardio", @"Inne", nil];
}

- (void)rebuildExerciseCache
{
    NSMutableArray *all = [NSMutableArray arrayWithArray:_builtin];
    for (NSDictionary *c in [_root objectForKey:@"custom"]) {
        NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary:c];
        [m setObject:[NSNumber numberWithBool:YES] forKey:@"custom"];
        [all addObject:m];
    }
    [all sortUsingComparator:^NSComparisonResult(id a, id b) {
        return [[a objectForKey:@"name"] compare:[b objectForKey:@"name"] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                               range:NSMakeRange(0, [[a objectForKey:@"name"] length]) locale:[NSLocale localeWithLocaleIdentifier:@"pl_PL"]];
    }];
    _all = all;
    _byId = [NSMutableDictionary dictionary];
    for (NSDictionary *e in all) [_byId setObject:e forKey:[e objectForKey:@"id"]];
}

- (NSArray *)allExercises
{
    if (!_all) [self rebuildExerciseCache];
    return _all;
}

- (NSDictionary *)exerciseForId:(NSString *)exId
{
    if (!_all) [self rebuildExerciseCache];
    return [_byId objectForKey:exId];
}

- (NSString *)nameForExerciseId:(NSString *)exId
{
    NSDictionary *e = [self exerciseForId:exId];
    return e ? [e objectForKey:@"name"] : @"(usunięte ćwiczenie)";
}

- (NSString *)addCustomExerciseNamed:(NSString *)name muscle:(NSString *)muscle
{
    NSString *n = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([n length] == 0) return nil;
    NSString *eid = [self newId:@"c:"];
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:eid, @"id", n, @"name", (muscle ? muscle : @"Inne"), @"muscle",
                       @"własne", @"equip", nil];
    [[_root objectForKey:@"custom"] addObject:d];
    _all = nil;
    [self save];
    return eid;
}

/* ---------- trening w toku ---------- */

- (NSMutableDictionary *)active
{
    id a = [_root objectForKey:@"active"];
    return [a isKindOfClass:[NSMutableDictionary class]] ? a : nil;
}

- (NSMutableDictionary *)blankWorkout
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [self newId:@"w"], @"id",
            [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], @"start",
            [NSMutableArray array], @"entries", nil];
}

- (void)startWorkout
{
    [_root setObject:[self blankWorkout] forKey:@"active"];
    [self save];
}

- (void)startWorkoutRepeating:(NSDictionary *)workout
{
    NSMutableDictionary *w = [self blankWorkout];
    for (NSDictionary *e in [workout objectForKey:@"entries"]) {
        NSMutableDictionary *ne = [NSMutableDictionary dictionaryWithObject:[e objectForKey:@"ex"] forKey:@"ex"];
        NSMutableArray *sets = [NSMutableArray array];
        for (NSDictionary *s in [e objectForKey:@"sets"]) {
            [sets addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                             [s objectForKey:@"kg"] ? [s objectForKey:@"kg"] : [NSNumber numberWithInt:0], @"kg",
                             [s objectForKey:@"reps"] ? [s objectForKey:@"reps"] : [NSNumber numberWithInt:0], @"reps",
                             [NSNumber numberWithBool:NO], @"done", nil]];
        }
        [ne setObject:sets forKey:@"sets"];
        [[w objectForKey:@"entries"] addObject:ne];
    }
    [_root setObject:w forKey:@"active"];
    [self save];
}

- (NSMutableDictionary *)blankSetLike:(NSDictionary *)prev
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            prev ? [prev objectForKey:@"kg"] : [NSNumber numberWithInt:0], @"kg",
            prev ? [prev objectForKey:@"reps"] : [NSNumber numberWithInt:0], @"reps",
            [NSNumber numberWithBool:NO], @"done", nil];
}

- (void)addExercise:(NSString *)exId toWorkout:(NSMutableDictionary *)w
{
    NSMutableDictionary *e = [NSMutableDictionary dictionaryWithObject:exId forKey:@"ex"];
    NSDictionary *last = [self lastSetsInfoForExercise:exId excludingWorkout:w];
    NSMutableArray *sets = [NSMutableArray array];
    NSArray *prevSets = [last objectForKey:@"sets"];
    if ([prevSets count]) {
        for (NSDictionary *s in prevSets) [sets addObject:[self blankSetLike:s]];
    } else {
        [sets addObject:[self blankSetLike:nil]];
    }
    [e setObject:sets forKey:@"sets"];
    [[w objectForKey:@"entries"] addObject:e];
    [self save];
}

- (void)removeEntryAtIndex:(NSUInteger)i fromWorkout:(NSMutableDictionary *)w
{
    NSMutableArray *a = [w objectForKey:@"entries"];
    if (i < [a count]) [a removeObjectAtIndex:i];
    [self save];
}

- (void)addSetToEntry:(NSMutableDictionary *)entry
{
    NSMutableArray *sets = [entry objectForKey:@"sets"];
    [sets addObject:[self blankSetLike:[sets lastObject]]];
    [self save];
}

- (BOOL)activeHasDoneSets
{
    NSDictionary *a = [self active];
    return a && [SLStore doneSetsInWorkout:a] > 0;
}

- (BOOL)finishActive
{
    NSMutableDictionary *a = [self active];
    if (!a || [SLStore doneSetsInWorkout:a] == 0) return NO;
    /* usuń niewykonane serie i puste ćwiczenia */
    NSMutableArray *entries = [a objectForKey:@"entries"];
    for (NSInteger i = (NSInteger)[entries count] - 1; i >= 0; i--) {
        NSMutableDictionary *e = [entries objectAtIndex:(NSUInteger)i];
        NSMutableArray *sets = [e objectForKey:@"sets"];
        for (NSInteger j = (NSInteger)[sets count] - 1; j >= 0; j--) {
            if (![[[sets objectAtIndex:(NSUInteger)j] objectForKey:@"done"] boolValue]) [sets removeObjectAtIndex:(NSUInteger)j];
        }
        if ([sets count] == 0) [entries removeObjectAtIndex:(NSUInteger)i];
    }
    [a setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"end"];
    [[_root objectForKey:@"workouts"] insertObject:a atIndex:0];
    [_root removeObjectForKey:@"active"];
    [self save];
    return YES;
}

- (void)discardActive
{
    [_root removeObjectForKey:@"active"];
    [self save];
}

/* ---------- historia ---------- */

- (NSArray *)workouts { return [_root objectForKey:@"workouts"]; }

- (void)deleteWorkoutWithId:(NSString *)wid
{
    NSMutableArray *a = [_root objectForKey:@"workouts"];
    for (NSUInteger i = 0; i < [a count]; i++) {
        if ([[[a objectAtIndex:i] objectForKey:@"id"] isEqual:wid]) { [a removeObjectAtIndex:i]; break; }
    }
    [self save];
}

- (NSArray *)historyForExercise:(NSString *)exId
{
    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *w in [self workouts]) {
        NSMutableArray *sets = [NSMutableArray array];
        for (NSDictionary *e in [w objectForKey:@"entries"]) {
            if (![[e objectForKey:@"ex"] isEqual:exId]) continue;
            for (NSDictionary *s in [e objectForKey:@"sets"]) {
                if ([[s objectForKey:@"done"] boolValue]) [sets addObject:s];
            }
        }
        if ([sets count]) {
            [out addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            [w objectForKey:@"start"], @"date", [w objectForKey:@"id"], @"wid", sets, @"sets", nil]];
        }
    }
    return out;
}

- (NSDictionary *)lastSetsInfoForExercise:(NSString *)exId excludingWorkout:(NSDictionary *)w
{
    NSString *skip = [w objectForKey:@"id"];
    for (NSDictionary *h in [self historyForExercise:exId]) {
        if ([[h objectForKey:@"wid"] isEqual:skip]) continue;
        return h;
    }
    return nil;
}

- (double)bestE1RMForExercise:(NSString *)exId excludingWorkout:(NSDictionary *)w
{
    NSString *skip = [w objectForKey:@"id"];
    double best = 0;
    for (NSDictionary *h in [self historyForExercise:exId]) {
        if ([[h objectForKey:@"wid"] isEqual:skip]) continue;
        for (NSDictionary *s in [h objectForKey:@"sets"]) {
            double v = sl_e1rm([[s objectForKey:@"kg"] doubleValue], [[s objectForKey:@"reps"] intValue]);
            if (v > best) best = v;
        }
    }
    return best;
}

/* ---------- statystyki ---------- */

+ (double)volumeOfWorkout:(NSDictionary *)w
{
    double v = 0;
    for (NSDictionary *e in [w objectForKey:@"entries"])
        for (NSDictionary *s in [e objectForKey:@"sets"])
            if ([[s objectForKey:@"done"] boolValue])
                v += sl_volume([[s objectForKey:@"kg"] doubleValue], [[s objectForKey:@"reps"] intValue]);
    return v;
}

+ (NSInteger)doneSetsInWorkout:(NSDictionary *)w
{
    NSInteger n = 0;
    for (NSDictionary *e in [w objectForKey:@"entries"])
        for (NSDictionary *s in [e objectForKey:@"sets"])
            if ([[s objectForKey:@"done"] boolValue]) n++;
    return n;
}

+ (NSInteger)exerciseCountInWorkout:(NSDictionary *)w
{
    NSInteger n = 0;
    for (NSDictionary *e in [w objectForKey:@"entries"]) {
        for (NSDictionary *s in [e objectForKey:@"sets"]) {
            if ([[s objectForKey:@"done"] boolValue]) { n++; break; }
        }
    }
    return n;
}

+ (double)durationOfWorkout:(NSDictionary *)w
{
    NSNumber *e = [w objectForKey:@"end"];
    NSNumber *s = [w objectForKey:@"start"];
    if (!e || !s) return 0;
    double d = [e doubleValue] - [s doubleValue];
    return d > 0 ? d : 0;
}

- (void)clearAll
{
    [_root removeAllObjects];
    [self load];
    _all = nil;
    [self save];
}

@end
