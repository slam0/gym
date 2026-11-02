#import "SLExercisesController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"
#import "sl_core.h"
#import <QuartzCore/QuartzCore.h>

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

@interface SLExerciseDetailController ()
{
    NSDictionary *_ex;
    NSArray *_history;
    UITableView *_table;
    UIImageView *_photo;
}
@end

@implementation SLExerciseDetailController

- (id)initWithExercise:(NSDictionary *)exercise
{
    if ((self = [super init])) {
        _ex = exercise;
        self.title = [[SLStore shared] displayNameForExercise:exercise];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
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

- (void)togglePhoto
{
    if (_photo.isAnimating) [_photo stopAnimating]; else [_photo startAnimating];     /* dotknięcie zatrzymuje / wznawia ruch */
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_photo stopAnimating];
}

- (void)buildHeader
{
    UIImage *f0 = SLExercisePhoto([_ex objectForKey:@"id"], 0), *f1 = SLExercisePhoto([_ex objectForKey:@"id"], 1);
    CGFloat photoH = (f0 && f1) ? 224 : 0;                       /* podgląd ruchu (2 klatki) nad wykresem */
    UIView *h = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 196 + photoH)];
    _photo = nil;
    if (photoH > 0) {
        /* ramka jak komórka listy grupowanej: biała, zaokrąglona, z szarą obwódką */
        UIView *frame = [[UIView alloc] initWithFrame:CGRectMake(10, 12, 300, 212)];
        frame.backgroundColor = [UIColor whiteColor];
        frame.layer.cornerRadius = 10;
        frame.layer.borderWidth = 1;
        frame.layer.borderColor = [UIColor colorWithWhite:0.68f alpha:1.0f].CGColor;
        _photo = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, 288, 200)];
        _photo.contentMode = UIViewContentModeScaleAspectFill;
        _photo.clipsToBounds = YES;
        _photo.layer.cornerRadius = 6;
        _photo.image = f0;
        _photo.animationImages = [NSArray arrayWithObjects:f0, f1, nil];
        _photo.animationDuration = 1.6;
        _photo.animationRepeatCount = 0;
        _photo.userInteractionEnabled = YES;
        [_photo addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePhoto)]];
        [frame addSubview:_photo];
        [h addSubview:frame];
        [_photo startAnimating];
    }
    SLChartView *chart = [[SLChartView alloc] initWithFrame:CGRectMake(10, 12 + photoH, 300, 172)];
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
        [lbs addObject:SLShortDateString([[[chrono objectAtIndex:from] objectForKey:@"date"] doubleValue])];
        if ([chrono count] - from > 1) [lbs addObject:SLShortDateString([[[chrono lastObject] objectForKey:@"date"] doubleValue])];
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

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 34; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    if (s == 0) return SLHeaderForTitle(GL(@"Wykres: szacowane 1RM"), nil);
    return SLHeaderForTitle(SLDateString([[[_history objectAtIndex:(NSUInteger)s - 1] objectForKey:@"date"] doubleValue]), nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"x"];
    c.detailTextLabel.text = nil;
    if (ip.section == 0) {
        if (![_history count]) { c.textLabel.text = GL(@"Jeszcze nie robiłeś tego ćwiczenia."); return c; }
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
            case 0: c.textLabel.text = [NSString stringWithFormat:GL(@"Największy ciężar:  %@"), SLWeightString(bestKg)]; break;
            case 1: c.textLabel.text = [NSString stringWithFormat:GL(@"Szacowane 1RM:  %@"), SLWeightString(bestE)]; break;
            case 2: c.textLabel.text = [NSString stringWithFormat:GL(@"Łączna objętość:  %@"), SLWeightString(vol)]; break;
            default: c.textLabel.text = [NSString stringWithFormat:GL(@"Treningów:  %lu"), (unsigned long)[_history count]]; break;
        }
        return c;
    }
    NSDictionary *s = [[[_history objectAtIndex:(NSUInteger)ip.section - 1] objectForKey:@"sets"] objectAtIndex:(NSUInteger)ip.row];
    c.textLabel.text = [NSString stringWithFormat:@"%ld.   %@ × %d", (long)ip.row + 1,
                        SLWeightString([[s objectForKey:@"kg"] doubleValue]), [[s objectForKey:@"reps"] intValue]];
    return c;
}

@end
