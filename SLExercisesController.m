#import "SLExercisesController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLViews.h"
#import "sl_core.h"

@implementation SLExercisesController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadList];
}

- (void)didSelectExercise:(NSDictionary *)ex
{
    [self.navigationController pushViewController:[[SLExerciseDetailController alloc] initWithExercise:ex] animated:YES];
}

@end

/* ---------------------------------------------------------------------- */

static NSString *SLShortDate(double ts)
{
    static NSDateFormatter *f;
    if (!f) {
        f = [[NSDateFormatter alloc] init];
        f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"pl_PL"];
        f.dateFormat = @"d MMM";
    }
    return [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

@interface SLExerciseDetailController ()
{
    NSDictionary *_ex;
    NSArray *_history;
    UITableView *_table;
}
@end

@implementation SLExerciseDetailController

- (id)initWithExercise:(NSDictionary *)exercise
{
    if ((self = [super init])) {
        _ex = exercise;
        self.title = [exercise objectForKey:@"name"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.allowsSelection = NO;
    _table.rowHeight = 44;
    SLStyleTable(_table);
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _history = [[SLStore shared] historyForExercise:[_ex objectForKey:@"id"]];
    [self buildHeader];
    [_table reloadData];
}

- (void)buildHeader
{
    UIView *h = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 196)];
    SLChartView *chart = [[SLChartView alloc] initWithFrame:CGRectMake(10, 12, 300, 172)];
    NSMutableArray *vals = [NSMutableArray array];
    NSMutableArray *lbs = [NSMutableArray array];
    NSArray *chrono = [[_history reverseObjectEnumerator] allObjects];
    NSUInteger from = [chrono count] > 20 ? [chrono count] - 20 : 0;
    for (NSUInteger i = from; i < [chrono count]; i++) {
        double best = 0;
        for (NSDictionary *s in [[chrono objectAtIndex:i] objectForKey:@"sets"]) {
            double v = sl_e1rm([[s objectForKey:@"kg"] doubleValue], [[s objectForKey:@"reps"] intValue]);
            if (v > best) best = v;
        }
        [vals addObject:[NSNumber numberWithDouble:[SLStore shared].units == 1 ? sl_kg_to_lb(best) : best]];
    }
    if ([chrono count]) {
        [lbs addObject:SLShortDate([[[chrono objectAtIndex:from] objectForKey:@"date"] doubleValue])];
        if ([chrono count] - from > 1) [lbs addObject:SLShortDate([[[chrono lastObject] objectForKey:@"date"] doubleValue])];
    }
    chart.values = vals;
    chart.labels = lbs;
    [h addSubview:chart];
    _table.tableHeaderView = h;
}

/* sekcja 0: statystyki; potem po jednej sekcji na trening */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 1 + (NSInteger)[_history count]; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    if (s == 0) return [_history count] ? 4 : 1;
    return (NSInteger)[[[_history objectAtIndex:(NSUInteger)s - 1] objectForKey:@"sets"] count];
}

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    if (s == 0) return SLHeaderForTitle(@"Wykres: szacowane 1RM", nil);
    return SLHeaderForTitle(SLDateString([[[_history objectAtIndex:(NSUInteger)s - 1] objectForKey:@"date"] doubleValue]), nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"x"];
    c.detailTextLabel.text = nil;
    c.textLabel.font = [UIFont boldSystemFontOfSize:16];
    if (ip.section == 0) {
        if (![_history count]) { c.textLabel.text = @"Jeszcze nie robiłeś tego ćwiczenia."; return c; }
        double bestKg = 0, bestE = 0, vol = 0;
        for (NSDictionary *h in _history) {
            for (NSDictionary *s in [h objectForKey:@"sets"]) {
                double kg = [[s objectForKey:@"kg"] doubleValue];
                int reps = [[s objectForKey:@"reps"] intValue];
                if (kg > bestKg) bestKg = kg;
                double e = sl_e1rm(kg, reps);
                if (e > bestE) bestE = e;
                vol += sl_volume(kg, reps);
            }
        }
        switch (ip.row) {
            case 0: c.textLabel.text = [NSString stringWithFormat:@"Największy ciężar:  %@", SLWeightString(bestKg)]; break;
            case 1: c.textLabel.text = [NSString stringWithFormat:@"Szacowane 1RM:  %@", SLWeightString(bestE)]; break;
            case 2: c.textLabel.text = [NSString stringWithFormat:@"Łączna objętość:  %@", SLWeightString(vol)]; break;
            default: c.textLabel.text = [NSString stringWithFormat:@"Treningów:  %lu", (unsigned long)[_history count]]; break;
        }
        return c;
    }
    NSDictionary *s = [[[_history objectAtIndex:(NSUInteger)ip.section - 1] objectForKey:@"sets"] objectAtIndex:(NSUInteger)ip.row];
    c.textLabel.text = [NSString stringWithFormat:@"%ld.   %@ × %d", (long)ip.row + 1,
                        SLWeightString([[s objectForKey:@"kg"] doubleValue]), [[s objectForKey:@"reps"] intValue]];
    return c;
}

@end
