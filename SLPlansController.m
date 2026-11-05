#import "SLPlansController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"

/* ---------- gotowe programy ---------- */

typedef struct { NSString *name; NSString *ids; } SLProgDay;       /* ids: oddzielone przecinkami */
typedef struct { NSString *name; NSString *desc; int days; SLProgDay day[3]; } SLProgram;

static const SLProgram kPrograms[] = {
    { @"Całe ciało 3×", @"Początkujący, 3 dni w tygodniu", 3, {
        { @"Całe ciało A", @"b:barbell-squat,b:barbell-bench-press,b:bent-over-barbell-row,b:standing-barbell-overhead-press,b:plank" },
        { @"Całe ciało B", @"b:barbell-deadlift,b:incline-dumbbell-press,b:lat-pulldown,b:dumbbell-lateral-raise,b:barbell-curl,b:triceps-pushdown" },
        { @"Całe ciało C", @"b:leg-press,b:dumbbell-bench-press,b:seated-cable-row,b:seated-dumbbell-shoulder-press,b:hanging-knee-raise" } } },
    { @"Push / Pull / Nogi", @"Średniozaawansowani, 3–6 dni w tygodniu", 3, {
        { @"Push (klatka, barki, triceps)", @"b:barbell-bench-press,b:standing-barbell-overhead-press,b:incline-dumbbell-press,b:dumbbell-lateral-raise,b:triceps-pushdown,b:lying-barbell-triceps-extension" },
        { @"Pull (plecy, biceps)", @"b:pull-up,b:bent-over-barbell-row,b:lat-pulldown,b:seated-cable-row,b:face-pull,b:barbell-curl,b:hammer-curl" },
        { @"Nogi", @"b:barbell-squat,b:romanian-deadlift,b:leg-press,b:leg-extensions,b:lying-leg-curls,b:standing-calf-raises" } } },
    { @"Góra / Dół", @"4 dni w tygodniu (góra, dół, góra, dół)", 2, {
        { @"Góra ciała", @"b:barbell-bench-press,b:bent-over-barbell-row,b:standing-barbell-overhead-press,b:lat-pulldown,b:dumbbell-bicep-curl,b:triceps-pushdown" },
        { @"Dół ciała", @"b:barbell-squat,b:romanian-deadlift,b:leg-press,b:lying-leg-curls,b:standing-calf-raises,b:crunches" } } },
    { @"Maszyny dla początkujących", @"Prosty trening całego ciała na maszynach", 1, {
        { @"Maszyny", @"b:machine-chest-press,b:lat-pulldown,b:machine-shoulder-press,b:leg-press,b:seated-leg-curl,b:machine-row,b:crunches" } } },
    { @"Ręce i brzuch", @"Dodatkowy trening na ramiona i brzuch", 1, {
        { @"Ręce i brzuch", @"b:ez-bar-curl,b:hammer-curl,b:cable-curl,b:triceps-pushdown-rope-attachment,b:lying-barbell-triceps-extension,b:hanging-leg-raise,b:cable-crunch" } } },
    { @"Masa ciała", @"Bez sprzętu i na drążku", 1, {
        { @"Masa ciała", @"b:push-up,b:chin-up,b:bench-dips,b:glute-bridge,b:crunches,b:plank,b:burpee" } } },
};
#define NPROGRAMS ((NSInteger)(sizeof(kPrograms) / sizeof(kPrograms[0])))

static NSArray *SLIdsFromString(NSString *s) { return [s componentsSeparatedByString:@","]; }

/* ---------- wspólne ---------- */

static NSString *SLExerciseSummary(NSArray *ids)
{
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *i in ids) {
        NSString *n = [[SLStore shared] nameForExerciseId:i];
        if (n) [names addObject:n];
    }
    return [names componentsJoinedByString:@", "];
}

static NSString *SLTrimmed(NSString *s)
{
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/* Zaczyna trening z listy ćwiczeń i przechodzi na Główną. */
static void SLStartFromIds(NSArray *ids, UIViewController *from)
{
    if ([ids count] == 0) return;
    if ([[SLStore shared] active]) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Trwa już trening") message:GL(@"Zakończ albo usuń trwający trening, zanim zaczniesz nowy.")
                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        return;
    }
    [[SLStore shared] startWorkoutFromExerciseIds:ids defaultSets:3];
    [from.navigationController popToRootViewControllerAnimated:NO];
    from.tabBarController.selectedIndex = 2;       /* Główna */
}

/* Okienko "nazwa planu", obsługiwane przez pomocniczy obiekt, żeby dało się je wywołać z dowolnego miejsca. */
@interface SLPlanSaver : NSObject <UIAlertViewDelegate>
@property (nonatomic, copy) NSArray *ids;
@end

static SLPlanSaver *gSaver;     /* trzyma obiekt do zamknięcia okienka */

@implementation SLPlanSaver
- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i
{
    if (i != a.cancelButtonIndex) {
        NSString *name = SLTrimmed([a textFieldAtIndex:0].text);
        if ([name length]) {
            [[SLStore shared] addPlanNamed:name exercises:self.ids];
            UIAlertView *ok = [[UIAlertView alloc] initWithTitle:GL(@"Plan zapisany") message:GL(@"Znajdziesz go w zakładce Plany.")
                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [ok show];
        }
    }
    gSaver = nil;
}
@end

void SLPromptSavePlan(NSString *suggestedName, NSArray *exerciseIds, id owner)
{
    (void)owner;
    if ([exerciseIds count] == 0) return;
    gSaver = [[SLPlanSaver alloc] init];
    gSaver.ids = exerciseIds;
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Zapisz jako plan") message:GL(@"Podaj nazwę planu") delegate:gSaver
                                      cancelButtonTitle:GL(@"Anuluj") otherButtonTitles:GL(@"Zapisz"), nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *f = [a textFieldAtIndex:0];
    f.text = suggestedName;
    f.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [a show];
}

/* ====================================================================== */
#pragma mark - lista planów

@interface SLPlansController ()
{
    UITableView *_table;
}
@end

@implementation SLPlansController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Plany");
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
    self.navigationItem.rightBarButtonItem = SLBarButton(@"+", self, @selector(newPlan));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_table reloadData];
}

- (void)newPlan
{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Nowy plan") message:GL(@"Podaj nazwę planu") delegate:self
                                      cancelButtonTitle:GL(@"Anuluj") otherButtonTitles:GL(@"Dalej"), nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    [a textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [a show];
}

- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i
{
    if (i == a.cancelButtonIndex) return;
    NSString *name = SLTrimmed([a textFieldAtIndex:0].text);
    if ([name length] == 0) return;
    NSDictionary *p = [[SLStore shared] addPlanNamed:name exercises:[NSArray array]];
    [self.navigationController pushViewController:[[SLPlanDetailController alloc] initWithPlanId:[p objectForKey:@"id"]] animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 2; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    if (s == 0) { NSInteger n = (NSInteger)[[[SLStore shared] plans] count]; return n > 0 ? n : 1; }
    return NPROGRAMS;
}

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    return SLHeaderForTitle(s == 0 ? GL(@"Moje plany") : GL(@"Gotowe programy"), nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"p"];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    c.textLabel.font = [UIFont boldSystemFontOfSize:17];
    if (ip.section == 0) {
        NSArray *plans = [[SLStore shared] plans];
        if ([plans count] == 0) {
            c.textLabel.text = GL(@"Brak planów");
            c.detailTextLabel.text = GL(@"Dotknij +, zapisz trening z historii albo wybierz gotowy program.");
            c.accessoryType = UITableViewCellAccessoryNone;
            return c;
        }
        NSDictionary *p = [plans objectAtIndex:(NSUInteger)ip.row];
        NSArray *ids = [p objectForKey:@"ex"];
        c.textLabel.text = [p objectForKey:@"name"];
        c.detailTextLabel.text = [ids count] ? [NSString stringWithFormat:@"%@: %@", SLCountString((long)[ids count], SLNounExercise), SLExerciseSummary(ids)]
                                             : GL(@"Pusty plan: dodaj ćwiczenia");
        return c;
    }
    const SLProgram *pr = &kPrograms[ip.row];
    c.textLabel.text = GL(pr->name);
    c.detailTextLabel.text = GL(pr->desc);
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 0) {
        NSArray *plans = [[SLStore shared] plans];
        if ([plans count] == 0) return;
        NSString *pid = [[plans objectAtIndex:(NSUInteger)ip.row] objectForKey:@"id"];
        [self.navigationController pushViewController:[[SLPlanDetailController alloc] initWithPlanId:pid] animated:YES];
    } else {
        [self.navigationController pushViewController:[[SLProgramController alloc] initWithProgramIndex:ip.row] animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)ip
{
    return ip.section == 0 && [[[SLStore shared] plans] count] > 0;
}

- (NSString *)tableView:(UITableView *)t titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)ip { return GL(@"Usuń"); }

- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip
{
    if (style != UITableViewCellEditingStyleDelete) return;
    NSArray *plans = [[SLStore shared] plans];
    if ((NSUInteger)ip.row >= [plans count]) return;
    [[SLStore shared] deletePlanWithId:[[plans objectAtIndex:(NSUInteger)ip.row] objectForKey:@"id"]];
    [t reloadData];
}

@end

/* ====================================================================== */
#pragma mark - szczegóły planu

@interface SLPlanDetailController ()
{
    NSString *_planId;
    NSString *_name;                 /* dla podglądu z programu */
    NSMutableArray *_templateIds;
    UITableView *_table;
    BOOL _renaming;
}
@end

@implementation SLPlanDetailController

- (id)initWithPlanId:(NSString *)planId
{
    if ((self = [super init])) {
        _planId = [planId copy];
        self.title = [[self plan] objectForKey:@"name"];
    }
    return self;
}

- (id)initWithTemplateName:(NSString *)name exercises:(NSArray *)ids
{
    if ((self = [super init])) {
        _name = [name copy];
        _templateIds = [NSMutableArray arrayWithArray:ids];
        self.title = name;
    }
    return self;
}

- (NSMutableDictionary *)plan
{
    for (NSMutableDictionary *p in [[SLStore shared] plans])
        if ([[p objectForKey:@"id"] isEqual:_planId]) return p;
    return nil;
}

- (BOOL)editable { return _planId != nil; }

- (NSMutableArray *)ids
{
    if (![self editable]) return _templateIds;
    NSMutableDictionary *p = [self plan];
    id ex = [p objectForKey:@"ex"];
    if (![ex isKindOfClass:[NSMutableArray class]]) {
        ex = [NSMutableArray arrayWithArray:ex];
        [p setObject:ex forKey:@"ex"];
    }
    return ex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 56;
    SLStyleTable(_table);
    [self buildFooter];
    [self.view addSubview:_table];
    if ([self editable]) self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)buildFooter
{
    BOOL ed = [self editable];
    UIView *foot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, ed ? 190 : 140)];
    UIButton *start = SLGelButton(GL(@"Rozpocznij trening"), 0, CGRectMake(15, 16, 290, 50));
    start.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    [start addTarget:self action:@selector(startTapped) forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:start];
    if (ed) {
        UIButton *add = SLGelButton(GL(@"+ Dodaj ćwiczenie"), 1, CGRectMake(15, 78, 290, 46));
        [add addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
        [foot addSubview:add];
        UIButton *ren = SLGelButton(GL(@"Zmień nazwę"), 1, CGRectMake(15, 134, 290, 40));
        ren.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [ren addTarget:self action:@selector(renameTapped) forControlEvents:UIControlEventTouchUpInside];
        [foot addSubview:ren];
    } else {
        UIButton *save = SLGelButton(GL(@"Zapisz do moich planów"), 1, CGRectMake(15, 78, 290, 46));
        [save addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
        [foot addSubview:save];
    }
    _table.tableFooterView = foot;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self editable] && ![self plan]) { [self.navigationController popViewControllerAnimated:NO]; return; }
    [_table reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [_table setEditing:editing animated:animated];
}

- (void)startTapped
{
    NSArray *ids = [self ids];
    if ([ids count] == 0) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Pusty plan") message:GL(@"Dodaj do planu przynajmniej jedno ćwiczenie.")
                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        return;
    }
    SLStartFromIds(ids, self);
}

- (void)saveTapped
{
    SLPromptSavePlan(_name, [self ids], self);
}

- (void)addTapped
{
    SLPickerController *p = [[SLPickerController alloc] init];
    p.delegate = self;
    p.navigationItem.leftBarButtonItem = SLBarButton(GL(@"Anuluj"), self, @selector(closePicker));
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:p];
    SLStyleNavigationBar(nav.navigationBar);
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)closePicker { [self dismissViewControllerAnimated:YES completion:nil]; }

- (void)picker:(SLPickerController *)picker didPickExerciseId:(NSString *)exId
{
    NSMutableArray *ids = [self ids];
    if (![ids containsObject:exId]) [ids addObject:exId];
    [[SLStore shared] save];
    [self dismissViewControllerAnimated:YES completion:nil];
    [_table reloadData];
}

- (void)renameTapped
{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Zmień nazwę") message:GL(@"Podaj nazwę planu") delegate:self
                                      cancelButtonTitle:GL(@"Anuluj") otherButtonTitles:GL(@"Zapisz"), nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *f = [a textFieldAtIndex:0];
    f.text = [[self plan] objectForKey:@"name"];
    f.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [a show];
}

- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i
{
    if (i == a.cancelButtonIndex) return;
    NSString *name = SLTrimmed([a textFieldAtIndex:0].text);
    if ([name length] == 0) return;
    [[self plan] setObject:name forKey:@"name"];
    [[SLStore shared] save];
    self.title = name;
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[[self ids] count]; }

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSInteger n = (NSInteger)[[self ids] count];
    return SLHeaderForTitle(n ? SLCountString(n, SLNounExercise) : GL(@"Pusty plan: dodaj ćwiczenia"), nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"e"];
    NSString *exId = [[self ids] objectAtIndex:(NSUInteger)ip.row];
    NSDictionary *e = [[SLStore shared] exerciseForId:exId];
    c.imageView.image = SLExerciseThumb(exId);
    c.textLabel.text = [[SLStore shared] nameForExerciseId:exId];
    c.textLabel.font = [UIFont boldSystemFontOfSize:15];
    c.detailTextLabel.text = GL([e objectForKey:@"muscle"]);
    c.accessoryType = UITableViewCellAccessoryNone;
    return c;
}

- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)ip { return [self editable]; }
- (BOOL)tableView:(UITableView *)t canMoveRowAtIndexPath:(NSIndexPath *)ip { return [self editable]; }

- (NSString *)tableView:(UITableView *)t titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)ip { return GL(@"Usuń"); }

- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip
{
    if (style != UITableViewCellEditingStyleDelete) return;
    [[self ids] removeObjectAtIndex:(NSUInteger)ip.row];
    [[SLStore shared] save];
    [t reloadData];
}

- (void)tableView:(UITableView *)t moveRowAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to
{
    NSMutableArray *ids = [self ids];
    id obj = [ids objectAtIndex:(NSUInteger)from.row];
    [ids removeObjectAtIndex:(NSUInteger)from.row];
    [ids insertObject:obj atIndex:(NSUInteger)to.row];
    [[SLStore shared] save];
}

@end

/* ====================================================================== */
#pragma mark - gotowy program

@interface SLProgramController ()
{
    NSInteger _index;
    UITableView *_table;
}
@end

@implementation SLProgramController

- (id)initWithProgramIndex:(NSInteger)index
{
    if ((self = [super init])) {
        _index = index;
        self.title = GL(kPrograms[index].name);
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
    _table.rowHeight = 74;
    SLStyleTable(_table);
    UIView *foot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    UIButton *all = SLGelButton(GL(@"Dodaj wszystkie dni do planów"), 0, CGRectMake(15, 18, 290, 46));
    [all addTarget:self action:@selector(addAll) forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:all];
    _table.tableFooterView = foot;
    [self.view addSubview:_table];
}

- (void)addAll
{
    const SLProgram *pr = &kPrograms[_index];
    for (int d = 0; d < pr->days; d++)
        [[SLStore shared] addPlanNamed:GL(pr->day[d].name) exercises:SLIdsFromString(pr->day[d].ids)];
    UIAlertView *ok = [[UIAlertView alloc] initWithTitle:GL(@"Dodano do planów")
                                                 message:[NSString stringWithFormat:@"%@: %@", GL(@"Dni"), [NSString stringWithFormat:@"%d", pr->days]]
                                                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [ok show];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return kPrograms[_index].days; }

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"d"];
    const SLProgDay *d = &kPrograms[_index].day[ip.row];
    c.textLabel.text = GL(d->name);
    c.textLabel.font = [UIFont boldSystemFontOfSize:17];
    c.detailTextLabel.numberOfLines = 2;
    c.detailTextLabel.text = SLExerciseSummary(SLIdsFromString(d->ids));
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    const SLProgDay *d = &kPrograms[_index].day[ip.row];
    [self.navigationController pushViewController:[[SLPlanDetailController alloc] initWithTemplateName:GL(d->name) exercises:SLIdsFromString(d->ids)] animated:YES];
}

@end
