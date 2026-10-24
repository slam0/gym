#import "SLHistoryController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLViews.h"
#import "sl_core.h"

/* początek bieżącego tygodnia (poniedziałek 00:00) */
static NSTimeInterval SLWeekStart(void)
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    cal.firstWeekday = 2;
    NSDate *now = [NSDate date];
    NSDateComponents *c = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
    NSInteger back = (c.weekday + 5) % 7;       /* pn = 0 ... nd = 6 */
    NSDateComponents *day = [[NSDateComponents alloc] init];
    day.day = -back;
    NSDate *monday = [cal dateByAddingComponents:day toDate:now options:0];
    NSDateComponents *mc = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:monday];
    return [[cal dateFromComponents:mc] timeIntervalSince1970];
}

@interface SLHistoryController ()
{
    UITableView *_table;
    UILabel *_empty;
}
@end

@implementation SLHistoryController

- (id)init
{
    if ((self = [super init])) self.title = @"Historia";
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
    _table.rowHeight = 62;
    SLStyleTable(_table);
    [self.view addSubview:_table];
    _empty = [[UILabel alloc] initWithFrame:CGRectMake(30, 120, 260, 80)];
    _empty.backgroundColor = [UIColor clearColor];
    _empty.numberOfLines = 3;
    _empty.textAlignment = NSTextAlignmentCenter;
    _empty.font = [UIFont systemFontOfSize:16];
    _empty.textColor = SLSubtleColor();
    _empty.text = @"Tu pojawią się twoje zakończone treningi.";
    [self.view addSubview:_empty];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

- (void)reload
{
    NSArray *ws = [[SLStore shared] workouts];
    _empty.hidden = [ws count] > 0;
    _table.hidden = [ws count] == 0;
    [_table reloadData];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[[[SLStore shared] workouts] count]; }

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSTimeInterval ws = SLWeekStart();
    long n = 0;
    double vol = 0;
    for (NSDictionary *w in [[SLStore shared] workouts]) {
        if ([[w objectForKey:@"start"] doubleValue] >= ws) { n++; vol += [SLStore volumeOfWorkout:w]; }
    }
    NSString *right = [NSString stringWithFormat:@"%ld %@ · %@", n, SLPlural(n, @"trening", @"treningi", @"treningów"), SLWeightString(vol)];
    return SLHeaderForTitle(@"Ten tydzień", right);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"w"];
    NSDictionary *w = [[[SLStore shared] workouts] objectAtIndex:(NSUInteger)ip.row];
    c.textLabel.text = SLDateTimeString([[w objectForKey:@"start"] doubleValue]);
    long min = (long)([SLStore durationOfWorkout:w] / 60.0 + 0.5);
    c.detailTextLabel.text = [NSString stringWithFormat:@"%ld min · %@ · %@ · %@", min,
        SLCountString([SLStore exerciseCountInWorkout:w], @"ćwiczenie", @"ćwiczenia", @"ćwiczeń"),
        SLCountString([SLStore doneSetsInWorkout:w], @"seria", @"serie", @"serii"),
        SLWeightString([SLStore volumeOfWorkout:w])];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *w = [[[SLStore shared] workouts] objectAtIndex:(NSUInteger)ip.row];
    [self.navigationController pushViewController:[[SLWorkoutDetailController alloc] initWithWorkout:w] animated:YES];
}

- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }

- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip
{
    if (style != UITableViewCellEditingStyleDelete) return;
    NSDictionary *w = [[[SLStore shared] workouts] objectAtIndex:(NSUInteger)ip.row];
    [[SLStore shared] deleteWorkoutWithId:[w objectForKey:@"id"]];
    [self reload];
}

- (NSString *)tableView:(UITableView *)t titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)ip { return @"Usuń"; }

@end

/* ---------------------------------------------------------------------- */

@interface SLWorkoutDetailController ()
{
    NSDictionary *_w;
    UITableView *_table;
}
@end

@implementation SLWorkoutDetailController

- (id)initWithWorkout:(NSDictionary *)workout
{
    if ((self = [super init])) {
        _w = workout;
        self.title = SLDateString([[workout objectForKey:@"start"] doubleValue]);
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

    UIView *foot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    UIButton *again = SLGelButton(@"Powtórz ten trening", 0, CGRectMake(15, 18, 290, 46));
    [again addTarget:self action:@selector(repeatTapped) forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:again];
    _table.tableFooterView = foot;

    NSString *summary = [NSString stringWithFormat:@"%ld min", (long)([SLStore durationOfWorkout:_w] / 60.0 + 0.5)];
    UIView *head = SLHeaderForTitle(summary, SLWeightString([SLStore volumeOfWorkout:_w]));
    head.frame = CGRectMake(0, 0, 320, 26);
    _table.tableHeaderView = head;
    [self.view addSubview:_table];
}

- (NSArray *)entries { return [_w objectForKey:@"entries"]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return (NSInteger)[[self entries] count]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[[[[self entries] objectAtIndex:(NSUInteger)s] objectForKey:@"sets"] count]; }
- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }
- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSDictionary *e = [[self entries] objectAtIndex:(NSUInteger)s];
    return SLHeaderForTitle([[SLStore shared] nameForExerciseId:[e objectForKey:@"ex"]], nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"d"];
    NSDictionary *e = [[self entries] objectAtIndex:(NSUInteger)ip.section];
    NSDictionary *s = [[e objectForKey:@"sets"] objectAtIndex:(NSUInteger)ip.row];
    double kg = [[s objectForKey:@"kg"] doubleValue];
    int reps = [[s objectForKey:@"reps"] intValue];
    BOOL pr = [[s objectForKey:@"pr"] boolValue];
    c.textLabel.text = [NSString stringWithFormat:@"%ld.   %@ × %d%@", (long)ip.row + 1, SLWeightString(kg), reps, pr ? @"   ★" : @""];
    c.detailTextLabel.text = nil;
    c.textLabel.font = [UIFont boldSystemFontOfSize:16];
    return c;
}

- (void)repeatTapped
{
    if ([[SLStore shared] active]) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Trwa już trening" message:@"Zakończ albo usuń trwający trening, zanim zaczniesz nowy."
                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        return;
    }
    [[SLStore shared] startWorkoutRepeating:_w];
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.tabBarController.selectedIndex = 1;
}

@end
