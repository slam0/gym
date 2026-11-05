#import "SLStats.h"
#import "SLStore.h"
#import "sl_core.h"

@implementation SLStats

+ (NSCalendar *)calendar
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    cal.firstWeekday = 2;
    return cal;
}

+ (NSTimeInterval)weekStartWeeksAgo:(NSInteger)weeksAgo
{
    NSCalendar *cal = [self calendar];
    NSDate *now = [NSDate date];
    NSDateComponents *c = [cal components:NSWeekdayCalendarUnit fromDate:now];
    NSInteger back = (c.weekday + 5) % 7;                     /* pn = 0 ... nd = 6 */
    NSDateComponents *day = [[NSDateComponents alloc] init];
    day.day = -back - 7 * weeksAgo;
    NSDate *monday = [cal dateByAddingComponents:day toDate:now options:0];
    NSDateComponents *mc = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:monday];
    return [[cal dateFromComponents:mc] timeIntervalSince1970];
}

/* numer tygodnia wstecz dla danego czasu: 0 = bieżący, <0 = przyszłość */
+ (NSInteger)weeksAgoForTime:(NSTimeInterval)ts currentStart:(NSTimeInterval)cur
{
    if (ts >= cur) return 0;
    return (NSInteger)((cur - ts) / 604800.0) + (((cur - ts) / 604800.0) > (NSInteger)((cur - ts) / 604800.0) ? 1 : 0);
}

+ (NSArray *)weeklyValues:(NSInteger)n volume:(BOOL)volume
{
    NSMutableArray *vals = [NSMutableArray array];
    for (NSInteger i = 0; i < n; i++) [vals addObject:[NSNumber numberWithDouble:0]];
    NSTimeInterval cur = [self weekStartWeeksAgo:0];
    for (NSDictionary *w in [[SLStore shared] workouts]) {
        NSInteger ago = [self weeksAgoForTime:[[w objectForKey:@"start"] doubleValue] currentStart:cur];
        if (ago < 0 || ago >= n) continue;
        NSUInteger idx = (NSUInteger)(n - 1 - ago);
        double add = volume ? [SLStore volumeOfWorkout:w] : 1.0;
        [vals replaceObjectAtIndex:idx withObject:[NSNumber numberWithDouble:[[vals objectAtIndex:idx] doubleValue] + add]];
    }
    return vals;
}

+ (NSArray *)weeklyCounts:(NSInteger)n { return [self weeklyValues:n volume:NO]; }
+ (NSArray *)weeklyVolumes:(NSInteger)n { return [self weeklyValues:n volume:YES]; }

+ (NSInteger)weekStreak
{
    NSArray *workouts = [[SLStore shared] workouts];
    if ([workouts count] == 0) return 0;
    NSTimeInterval cur = [self weekStartWeeksAgo:0];
    NSMutableSet *weeks = [NSMutableSet set];
    for (NSDictionary *w in workouts) {
        NSInteger ago = [self weeksAgoForTime:[[w objectForKey:@"start"] doubleValue] currentStart:cur];
        if (ago >= 0) [weeks addObject:[NSNumber numberWithInteger:ago]];
    }
    NSInteger i = [weeks containsObject:[NSNumber numberWithInteger:0]] ? 0 : 1;   /* tydzień bez treningu jeszcze nie przerywa serii */
    NSInteger streak = 0;
    while ([weeks containsObject:[NSNumber numberWithInteger:i]]) { streak++; i++; }
    return streak;
}

+ (NSInteger)workoutsSince:(NSTimeInterval)ts
{
    NSInteger n = 0;
    for (NSDictionary *w in [[SLStore shared] workouts])
        if ([[w objectForKey:@"start"] doubleValue] >= ts) n++;
    return n;
}

+ (NSArray *)records
{
    SLStore *st = [SLStore shared];
    NSMutableDictionary *byEx = [NSMutableDictionary dictionary];
    /* od najstarszego, żeby "date" wskazywała pierwszy raz, gdy rekord został ustanowiony */
    for (NSDictionary *w in [[[st workouts] reverseObjectEnumerator] allObjects]) {
        double date = [[w objectForKey:@"start"] doubleValue];
        for (NSDictionary *e in [w objectForKey:@"entries"]) {
            NSString *exId = [e objectForKey:@"ex"];
            NSMutableDictionary *r = [byEx objectForKey:exId];
            if (!r) {
                r = [NSMutableDictionary dictionaryWithObjectsAndKeys:exId, @"ex",
                     [NSNumber numberWithDouble:0], @"kg", [NSNumber numberWithDouble:0], @"e1rm",
                     [NSNumber numberWithDouble:0], @"vol", [NSNumber numberWithInt:0], @"kgReps",
                     [NSNumber numberWithDouble:date], @"date", nil];
                [byEx setObject:r forKey:exId];
            }
            for (NSDictionary *s in [e objectForKey:@"sets"]) {
                if (![[s objectForKey:@"done"] boolValue]) continue;
                double kg = [[s objectForKey:@"kg"] doubleValue];
                int reps = [[s objectForKey:@"reps"] intValue];
                double e1 = sl_e1rm(kg, reps), vol = sl_volume(kg, reps);
                if (kg > [[r objectForKey:@"kg"] doubleValue]) {
                    [r setObject:[NSNumber numberWithDouble:kg] forKey:@"kg"];
                    [r setObject:[NSNumber numberWithInt:reps] forKey:@"kgReps"];
                }
                if (e1 > [[r objectForKey:@"e1rm"] doubleValue] + 0.0001) {
                    [r setObject:[NSNumber numberWithDouble:e1] forKey:@"e1rm"];
                    [r setObject:[NSNumber numberWithDouble:date] forKey:@"date"];
                }
                if (vol > [[r objectForKey:@"vol"] doubleValue]) [r setObject:[NSNumber numberWithDouble:vol] forKey:@"vol"];
            }
        }
    }
    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *r in [byEx allValues])
        if ([[r objectForKey:@"e1rm"] doubleValue] > 0) [out addObject:r];
    [out sortUsingComparator:^NSComparisonResult(id a, id b) {
        double x = [[a objectForKey:@"e1rm"] doubleValue], y = [[b objectForKey:@"e1rm"] doubleValue];
        return x < y ? NSOrderedDescending : (x > y ? NSOrderedAscending : NSOrderedSame);
    }];
    return out;
}

+ (NSInteger)recordsSince:(NSTimeInterval)ts
{
    NSInteger n = 0;
    for (NSDictionary *r in [self records])
        if ([[r objectForKey:@"date"] doubleValue] >= ts) n++;
    return n;
}

+ (NSInteger)recordCountInWorkout:(NSDictionary *)w
{
    NSInteger n = 0;
    for (NSDictionary *e in [w objectForKey:@"entries"]) {
        for (NSDictionary *s in [e objectForKey:@"sets"]) {
            if ([[s objectForKey:@"done"] boolValue] && [[s objectForKey:@"pr"] boolValue]) { n++; break; }
        }
    }
    return n;
}

+ (NSDictionary *)setsByMuscleSince:(NSTimeInterval)ts
{
    SLStore *st = [SLStore shared];
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (NSDictionary *w in [st workouts]) {
        if ([[w objectForKey:@"start"] doubleValue] < ts) continue;
        for (NSDictionary *e in [w objectForKey:@"entries"]) {
            NSString *muscle = [[st exerciseForId:[e objectForKey:@"ex"]] objectForKey:@"muscle"];
            if (![muscle length]) muscle = @"Inne";
            long n = 0;
            for (NSDictionary *s in [e objectForKey:@"sets"]) if ([[s objectForKey:@"done"] boolValue]) n++;
            if (n == 0) continue;
            NSNumber *old = [out objectForKey:muscle];
            [out setObject:[NSNumber numberWithLong:(old ? [old longValue] : 0) + n] forKey:muscle];
        }
    }
    return out;
}

+ (NSInteger)dayKeyForDate:(NSDate *)d
{
    NSDateComponents *c = [[self calendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:d];
    return c.year * 10000 + c.month * 100 + c.day;
}

+ (NSDictionary *)workoutsByDay
{
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (NSDictionary *w in [[SLStore shared] workouts]) {
        NSNumber *key = [NSNumber numberWithInteger:[self dayKeyForDate:[NSDate dateWithTimeIntervalSince1970:[[w objectForKey:@"start"] doubleValue]]]];
        NSMutableArray *a = [out objectForKey:key];
        if (!a) { a = [NSMutableArray array]; [out setObject:a forKey:key]; }
        [a addObject:w];
    }
    return out;
}

@end
