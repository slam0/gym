#import "SLHomeController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"

/* Ekran główny: lista grupowana jak w Ustawieniach (sekcja z liczbami i sekcja z przyciskami). */

@interface SLHomeController ()
{
    UITableView *_table;
    NSString *_statsFooter, *_lastFooter;
    BOOL _canRepeat, _active;
}
@end

@implementation SLHomeController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Główna");
    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)viewDidLoad
{
    [super viewDidLoad];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.backgroundView = nil;
    _table.backgroundColor = SLBackgroundColor();
    [self.view addSubview:_table];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:SLStoreDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)refresh
{
    if (!self.isViewLoaded) return;
    SLStore *st = [SLStore shared];
    NSDictionary *t = [st totalStats];
    long n = [[t objectForKey:@"count"] longValue];
    long sets = [[t objectForKey:@"sets"] longValue], reps = [[t objectForKey:@"reps"] longValue];
    _statsFooter = n > 0 ? [NSString stringWithFormat:@"%@ · %@", SLCountString(sets, SLNounSet), SLCountString(reps, SLNounRep)]
                         : GL(@"Zacznij pierwszy trening, a tu pojawią się twoje liczby.");
    NSArray *ws = [st workouts];
    _active = [st active] != nil;
    _canRepeat = !_active && [ws count] > 0;
    if (_active) {
        _lastFooter = GL(@"Masz trwający trening. Dokończ go albo zakończ w zakładce Trening.");
    } else if ([ws count]) {
        NSDictionary *w = [ws objectAtIndex:0];
        _lastFooter = [NSString stringWithFormat:GL(@"Poprzedni trening: %@\n%@, %@"),
                       SLDateString([[w objectForKey:@"start"] doubleValue]),
                       SLCountString([SLStore doneSetsInWorkout:w], SLNounSet),
                       SLWeightString([SLStore volumeOfWorkout:w])];
    } else {
        _lastFooter = nil;
    }
    [_table reloadData];
}

#pragma mark - tabela

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 2; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    return s == 0 ? 3 : (_canRepeat ? 2 : 1);
}

- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s
{
    return s == 0 ? GL(@"Twoje treningi w liczbach") : nil;
}

- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s
{
    return s == 0 ? _statsFooter : _lastFooter;
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    if (ip.section == 0) {
        UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"stat"];
        if (!c) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"stat"];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSDictionary *tot = [[SLStore shared] totalStats];
        if (ip.row == 0) {
            c.textLabel.text = GL(@"Treningi");
            c.detailTextLabel.text = [NSString stringWithFormat:@"%ld", [[tot objectForKey:@"count"] longValue]];
        } else if (ip.row == 1) {
            c.textLabel.text = GL(@"Czas");
            c.detailTextLabel.text = SLLongDuration([[tot objectForKey:@"seconds"] doubleValue]);
        } else {
            c.textLabel.text = GL(@"Objętość");
            c.detailTextLabel.text = SLBigWeightString([[tot objectForKey:@"volume"] doubleValue]);
        }
        return c;
    }
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"btn"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"btn"];
        c.textLabel.textAlignment = NSTextAlignmentCenter;
        c.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    }
    c.textLabel.text = ip.row == 0 ? GL(_active ? @"Wróć do treningu" : @"Nowy trening") : GL(@"Powtórz poprzedni trening");
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 1) return;
    if (ip.row == 0) [self newTapped]; else [self repeatTapped];
}

- (void)newTapped
{
    SLStore *st = [SLStore shared];
    if (![st active]) [st startWorkout];
    self.tabBarController.selectedIndex = 1;
}

- (void)repeatTapped
{
    SLStore *st = [SLStore shared];
    NSArray *ws = [st workouts];
    if (![ws count]) return;
    if ([st active]) { self.tabBarController.selectedIndex = 1; return; }
    [st startWorkoutRepeating:[ws objectAtIndex:0]];
    self.tabBarController.selectedIndex = 1;
}

@end
