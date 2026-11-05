#import "SLProgressController.h"
#import "SLStore.h"
#import "SLStats.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"
#import "SLHistoryController.h"
#import "SLExercisesController.h"
#import "SLBodyController.h"
#import "sl_core.h"

#define DAY 86400.0

/* ====================================================================== */
#pragma mark - Postępy (główny ekran)

@interface SLProgressController ()
{
    UITableView *_table;
    SLStatView *_weekView, *_streakView, *_recordView;
}
@end

@implementation SLProgressController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Postępy");
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
    _table.rowHeight = 58;
    SLStyleTable(_table);

    UIView *head = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 98)];
    _weekView   = [[SLStatView alloc] initWithFrame:CGRectMake(10, 12, 96, 76)];
    _streakView = [[SLStatView alloc] initWithFrame:CGRectMake(112, 12, 96, 76)];
    _recordView = [[SLStatView alloc] initWithFrame:CGRectMake(214, 12, 96, 76)];
    _weekView.caption = GL(@"Ten tydzień");
    _streakView.caption = GL(@"Seria tyg.");
    _recordView.caption = GL(@"Rekordy");
    [head addSubview:_weekView];
    [head addSubview:_streakView];
    [head addSubview:_recordView];
    _table.tableHeaderView = head;
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _weekView.value = [NSString stringWithFormat:@"%ld", (long)[SLStats workoutsSince:[SLStats weekStartWeeksAgo:0]]];
    _streakView.value = [NSString stringWithFormat:@"%ld", (long)[SLStats weekStreak]];
    _recordView.value = [NSString stringWithFormat:@"%ld", (long)[SLStats recordsSince:[[NSDate date] timeIntervalSince1970] - 30 * DAY]];
    [_table reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 2; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return s == 0 ? 3 : 2; }
- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    return SLHeaderForTitle(s == 0 ? GL(@"Analiza treningów") : GL(@"Ciało"), nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"pr"];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    c.textLabel.font = [UIFont boldSystemFontOfSize:17];
    SLStore *st = [SLStore shared];
    if (ip.section == 0) {
        switch (ip.row) {
            case 0:
                c.textLabel.text = GL(@"Kalendarz");
                c.detailTextLabel.text = GL(@"Dni, w które trenowałeś");
                break;
            case 1:
                c.textLabel.text = GL(@"Rekordy");
                c.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", SLCountString((long)[[SLStats records] count], SLNounExercise), GL(@"z najlepszymi wynikami")];
                break;
            default:
                c.textLabel.text = GL(@"Analiza i wykresy");
                c.detailTextLabel.text = GL(@"Tygodnie, objętość, partie mięśni");
                break;
        }
    } else if (ip.row == 0) {
        c.textLabel.text = GL(@"Pomiary ciała");
        NSArray *w = [st measuresOfType:0];
        c.detailTextLabel.text = [w count] ? [NSString stringWithFormat:@"%@ · %@", GL(@"Waga"), SLWeightString([[[w objectAtIndex:0] objectForKey:@"v"] doubleValue])]
                                           : GL(@"Waga, biceps, klatka, talia, biodra, udo");
    } else {
        c.textLabel.text = GL(@"Zdjęcia postępów");
        NSUInteger n = [[st photos] count];
        c.detailTextLabel.text = n ? [NSString stringWithFormat:@"%lu", (unsigned long)n] : GL(@"Porównuj sylwetkę w czasie");
    }
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    UIViewController *vc;
    if (ip.section == 0) {
        vc = ip.row == 0 ? (UIViewController *)[[SLCalendarController alloc] init]
           : (ip.row == 1 ? (UIViewController *)[[SLRecordsController alloc] init] : (UIViewController *)[[SLAnalysisController alloc] init]);
    } else {
        vc = ip.row == 0 ? (UIViewController *)[[SLMeasuresController alloc] init] : (UIViewController *)[[SLPhotosController alloc] init];
    }
    [self.navigationController pushViewController:vc animated:YES];
}

@end

/* ====================================================================== */
#pragma mark - Kalendarz

@interface SLCalendarController ()
{
    UITableView *_table;
    SLCalendarView *_cal;
    UILabel *_monthLabel;
    NSInteger _year, _month;
    NSDictionary *_byDay;
    NSArray *_rows;                   /* treningi na liście: wybrany dzień albo cały miesiąc */
}
@end

@implementation SLCalendarController

- (id)init
{
    if ((self = [super init])) {
        self.title = GL(@"Kalendarz");
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:[NSDate date]];
        _year = c.year;
        _month = c.month;
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
    _table.rowHeight = 58;
    SLStyleTable(_table);

    UIView *head = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 322)];
    UIButton *prev = SLGelButton(@"‹", 1, CGRectMake(10, 8, 52, 36));
    prev.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    prev.tag = -1;
    [prev addTarget:self action:@selector(shiftMonth:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *next = SLGelButton(@"›", 1, CGRectMake(258, 8, 52, 36));
    next.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    next.tag = 1;
    [next addTarget:self action:@selector(shiftMonth:) forControlEvents:UIControlEventTouchUpInside];
    [head addSubview:prev];
    [head addSubview:next];
    _monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(66, 8, 188, 36)];
    _monthLabel.backgroundColor = [UIColor clearColor];
    _monthLabel.textAlignment = NSTextAlignmentCenter;
    _monthLabel.font = [UIFont boldSystemFontOfSize:19];
    _monthLabel.textColor = SLTextColor();
    SLStyleShadow(_monthLabel);
    [head addSubview:_monthLabel];
    _cal = [[SLCalendarView alloc] initWithFrame:CGRectMake(10, 52, 300, 258)];
    _cal.target = self;
    _cal.action = @selector(dayTapped);
    [head addSubview:_cal];
    _table.tableHeaderView = head;
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

- (void)shiftMonth:(UIButton *)b
{
    _month += b.tag;
    if (_month < 1) { _month = 12; _year--; }
    if (_month > 12) { _month = 1; _year++; }
    _cal.selectedDay = 0;
    [self reload];
}

- (void)dayTapped
{
    [self rebuildRows];
    [_table reloadData];
}

- (void)reload
{
    _byDay = [SLStats workoutsByDay];
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = SLLocale();
    f.dateFormat = @"LLLL yyyy";
    NSDateComponents *dc = [[NSDateComponents alloc] init];
    dc.year = _year; dc.month = _month; dc.day = 1;
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSString *s = [f stringFromDate:[cal dateFromComponents:dc]];
    _monthLabel.text = [s length] ? [[[s substringToIndex:1] uppercaseString] stringByAppendingString:[s substringFromIndex:1]] : s;
    NSMutableSet *marked = [NSMutableSet set];
    for (NSNumber *k in [_byDay allKeys]) {
        NSInteger key = [k integerValue];
        if (key / 10000 == _year && (key / 100) % 100 == _month) [marked addObject:[NSNumber numberWithInteger:key % 100]];
    }
    _cal.year = _year;
    _cal.month = _month;
    _cal.markedDays = marked;
    [self rebuildRows];
    [_table reloadData];
}

- (void)rebuildRows
{
    NSMutableArray *rows = [NSMutableArray array];
    NSInteger sel = _cal.selectedDay;
    for (NSDictionary *w in [[SLStore shared] workouts]) {
        NSInteger key = [SLStats dayKeyForDate:[NSDate dateWithTimeIntervalSince1970:[[w objectForKey:@"start"] doubleValue]]];
        if (key / 10000 != _year || (key / 100) % 100 != _month) continue;
        if (sel > 0 && key % 100 != sel) continue;
        [rows addObject:w];
    }
    _rows = rows;
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[_rows count]; }
- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSString *title = _cal.selectedDay > 0 ? GL(@"Treningi tego dnia") : GL(@"Treningi w miesiącu");
    return SLHeaderForTitle(title, [NSString stringWithFormat:@"%lu", (unsigned long)[_rows count]]);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"c"];
    NSDictionary *w = [_rows objectAtIndex:(NSUInteger)ip.row];
    c.textLabel.text = SLDateString([[w objectForKey:@"start"] doubleValue]);
    c.textLabel.font = [UIFont boldSystemFontOfSize:16];
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@, %@", SLCountString([SLStore exerciseCountInWorkout:w], SLNounExercise),
                              SLCountString([SLStore doneSetsInWorkout:w], SLNounSet), SLWeightString([SLStore volumeOfWorkout:w])];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    [self.navigationController pushViewController:[[SLWorkoutDetailController alloc] initWithWorkout:[_rows objectAtIndex:(NSUInteger)ip.row]] animated:YES];
}

@end

/* ====================================================================== */
#pragma mark - Rekordy

@interface SLRecordsController ()
{
    UITableView *_table;
    NSArray *_records;
}
@end

@implementation SLRecordsController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Rekordy");
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
    _table.rowHeight = 64;
    SLStyleTable(_table);
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _records = [SLStats records];
    [_table reloadData];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return [_records count] ? (NSInteger)[_records count] : 1; }
- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    return SLHeaderForTitle(GL(@"Rekordy osobiste"), [NSString stringWithFormat:@"%lu", (unsigned long)[_records count]]);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"rec"];
    c.textLabel.font = [UIFont boldSystemFontOfSize:15];
    if ([_records count] == 0) {
        c.textLabel.text = GL(@"Brak rekordów");
        c.detailTextLabel.text = GL(@"Zakończ trening z wykonanymi seriami, a pojawią się tutaj.");
        c.accessoryType = UITableViewCellAccessoryNone;
        return c;
    }
    NSDictionary *r = [_records objectAtIndex:(NSUInteger)ip.row];
    BOOL recent = [[r objectForKey:@"date"] doubleValue] >= [[NSDate date] timeIntervalSince1970] - 30 * DAY;
    NSString *name = [[SLStore shared] nameForExerciseId:[r objectForKey:@"ex"]];
    c.textLabel.text = recent ? [@"★ " stringByAppendingString:name] : name;
    c.detailTextLabel.text = [NSString stringWithFormat:@"1RM %@ · max %@ × %d · %@",
                              SLWeightString([[r objectForKey:@"e1rm"] doubleValue]), SLWeightString([[r objectForKey:@"kg"] doubleValue]),
                              [[r objectForKey:@"kgReps"] intValue], SLShortDateString([[r objectForKey:@"date"] doubleValue])];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    if ([_records count] == 0) return;
    NSDictionary *e = [[SLStore shared] exerciseForId:[[_records objectAtIndex:(NSUInteger)ip.row] objectForKey:@"ex"]];
    if (e) [self.navigationController pushViewController:[[SLExerciseDetailController alloc] initWithExercise:e] animated:YES];
}

@end

/* ====================================================================== */
#pragma mark - Analiza i wykresy

@interface SLAnalysisController ()
{
    UITableView *_table;
    UISegmentedControl *_range;
    SLBarChartView *_countChart, *_volumeChart;
    NSArray *_muscles;                  /* [{name, sets}] malejąco */
    long _total;
}
@end

@implementation SLAnalysisController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Analiza i wykresy");
    return self;
}

- (UILabel *)captionAt:(CGFloat)y text:(NSString *)text inView:(UIView *)v
{
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(12, y, 296, 18)];
    l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont boldSystemFontOfSize:13];
    l.textColor = SLTextColor();
    l.text = text;
    SLStyleShadow(l);
    [v addSubview:l];
    return l;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 64;
    _table.allowsSelection = NO;
    SLStyleTable(_table);

    UIView *head = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 336)];
    [self captionAt:8 text:GL(@"Treningi w tygodniu (8 tygodni)") inView:head];
    _countChart = [[SLBarChartView alloc] initWithFrame:CGRectMake(10, 28, 300, 120)];
    [head addSubview:_countChart];
    [self captionAt:158 text:[NSString stringWithFormat:@"%@, %@", GL(@"Objętość w tygodniu"), SLUnitName()] inView:head];
    _volumeChart = [[SLBarChartView alloc] initWithFrame:CGRectMake(10, 178, 300, 120)];
    [head addSubview:_volumeChart];
    _range = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:GL(@"7 dni"), GL(@"30 dni"), GL(@"90 dni"), GL(@"Wszystko"), nil]];
    _range.segmentedControlStyle = UISegmentedControlStyleBar;
    _range.frame = CGRectMake(10, 304, 300, 30);
    _range.selectedSegmentIndex = 1;
    _range.tintColor = SLRGB(SLP()->barTint, 1);
    [_range addTarget:self action:@selector(rangeChanged) forControlEvents:UIControlEventValueChanged];
    [head addSubview:_range];
    _table.tableHeaderView = head;
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

- (void)rangeChanged { [self reload]; }

- (void)reload
{
    /* wykresy tygodniowe */
    NSInteger n = 8;
    NSArray *counts = [SLStats weeklyCounts:n];
    NSArray *vols = [SLStats weeklyVolumes:n];
    NSMutableArray *vv = [NSMutableArray array], *labels = [NSMutableArray array];
    for (NSNumber *v in vols) {
        double kg = [v doubleValue];
        [vv addObject:[NSNumber numberWithDouble:[SLStore shared].units == 1 ? sl_kg_to_lb(kg) : kg]];
    }
    for (NSInteger i = 0; i < n; i++)
        [labels addObject:SLShortDateString([SLStats weekStartWeeksAgo:n - 1 - i])];
    _countChart.values = counts;
    _countChart.labels = labels;
    _volumeChart.values = vv;
    _volumeChart.labels = labels;

    /* partie mięśni */
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970], since = 0;
    switch (_range.selectedSegmentIndex) {
        case 0: since = now - 7 * DAY; break;
        case 1: since = now - 30 * DAY; break;
        case 2: since = now - 90 * DAY; break;
        default: since = 0; break;
    }
    NSDictionary *d = [SLStats setsByMuscleSince:since];
    NSMutableArray *m = [NSMutableArray array];
    _total = 0;
    for (NSString *k in d) {
        long v = [[d objectForKey:k] longValue];
        _total += v;
        [m addObject:[NSDictionary dictionaryWithObjectsAndKeys:k, @"name", [NSNumber numberWithLong:v], @"sets", nil]];
    }
    [m sortUsingComparator:^NSComparisonResult(id a, id b) {
        long x = [[a objectForKey:@"sets"] longValue], y = [[b objectForKey:@"sets"] longValue];
        return x < y ? NSOrderedDescending : (x > y ? NSOrderedAscending : NSOrderedSame);
    }];
    _muscles = m;
    [_table reloadData];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return [_muscles count] ? (NSInteger)[_muscles count] : 1; }
- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    return SLHeaderForTitle(GL(@"Partie mięśni (serie)"), _total ? SLCountString(_total, SLNounSet) : nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"mu"];
    c.textLabel.font = [UIFont boldSystemFontOfSize:16];
    UIView *bar = [c.contentView viewWithTag:91];
    UIView *track = [c.contentView viewWithTag:92];
    if (!bar) {
        track = [[UIView alloc] initWithFrame:CGRectMake(15, 51, 290, 6)];
        track.tag = 92;
        track.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.35f];
        track.layer.cornerRadius = 3;
        [c.contentView addSubview:track];
        bar = [[UIView alloc] initWithFrame:CGRectMake(15, 51, 0, 6)];
        bar.tag = 91;
        bar.layer.cornerRadius = 3;
        [c.contentView addSubview:bar];
    }
    bar.backgroundColor = SLAccentColor();
    if ([_muscles count] == 0) {
        c.textLabel.text = GL(@"Brak danych");
        c.detailTextLabel.text = GL(@"Brak wykonanych serii w tym okresie.");
        bar.frame = CGRectMake(15, 51, 0, 6);
        track.hidden = YES;
        return c;
    }
    track.hidden = NO;
    NSDictionary *m = [_muscles objectAtIndex:(NSUInteger)ip.row];
    long sets = [[m objectForKey:@"sets"] longValue];
    long first = [[[_muscles objectAtIndex:0] objectForKey:@"sets"] longValue];
    c.textLabel.text = GL([m objectForKey:@"name"]);
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %ld%%", SLCountString(sets, SLNounSet), _total ? (sets * 100 + _total / 2) / _total : 0L];
    bar.frame = CGRectMake(15, 51, first ? 290.0f * (CGFloat)sets / (CGFloat)first : 0, 6);
    return c;
}

@end
