#import "SLPickerController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"

/* Wybór partii mięśniowej dla własnego ćwiczenia */
@interface SLMuscleChooser : UITableViewController
@property (nonatomic, copy) NSString *exerciseName;
@property (nonatomic, copy) void (^onChoose)(NSString *muscle);
@end

@implementation SLMuscleChooser
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = GL(@"Partia mięśni");
    SLStyleTable(self.tableView);
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[[[SLStore shared] muscleGroups] count]; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"m"];
    c.textLabel.text = GL([[[SLStore shared] muscleGroups] objectAtIndex:(NSUInteger)ip.row]);
    c.detailTextLabel.text = nil;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    if (self.onChoose) self.onChoose([[[SLStore shared] muscleGroups] objectAtIndex:(NSUInteger)ip.row]);
}
@end

@interface SLPickerController ()
{
    UISearchBar *_search;
    NSArray *_sections;        /* [{title, items}] */
    NSString *_query;
}
@end

@implementation SLPickerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = GL(@"Ćwiczenia");
    self.view.backgroundColor = SLBackgroundColor();
    _search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _search.delegate = self;
    _search.placeholder = GL(@"Szukaj ćwiczenia");
    SLStyleSearchBar(_search);
    _search.autocorrectionType = UITextAutocorrectionTypeNo;
    _search.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.tableHeaderView = _search;
    self.table.rowHeight = 50;
    SLStyleTable(self.table);
    [self.view addSubview:self.table];
    self.navigationItem.rightBarButtonItem = SLBarButton(GL(@"Nowe"), self, @selector(addCustom));
    [self reloadList];
}

static NSString *Fold(NSString *s)
{
    /* bez wielkości liter i bez znaków diakrytycznych (ł zostaje, więc dopisujemy zamiennik) */
    NSString *f = [s stringByFoldingWithOptions:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch locale:[NSLocale localeWithLocaleIdentifier:@"pl_PL"]];
    f = [f stringByReplacingOccurrencesOfString:@"ł" withString:@"l"];
    return [f stringByReplacingOccurrencesOfString:@"ё" withString:@"е"];
}

- (void)reloadList
{
    NSString *q = Fold(_query ? _query : @"");
    NSMutableDictionary *byMuscle = [NSMutableDictionary dictionary];
    for (NSDictionary *e in [[SLStore shared] allExercises]) {
        if ([q length]) {
            NSString *hay = Fold([[SLStore shared] searchTextForExercise:e]);
            BOOL ok = YES;
            for (NSString *w in [q componentsSeparatedByString:@" "]) {
                if ([w length] && [hay rangeOfString:w].location == NSNotFound) { ok = NO; break; }
            }
            if (!ok) continue;
        }
        NSString *m = [e objectForKey:@"muscle"];
        NSMutableArray *a = [byMuscle objectForKey:m];
        if (!a) { a = [NSMutableArray array]; [byMuscle setObject:a forKey:m]; }
        [a addObject:e];
    }
    NSMutableArray *secs = [NSMutableArray array];
    NSMutableArray *order = [NSMutableArray arrayWithArray:[[SLStore shared] muscleGroups]];
    for (NSString *m in [byMuscle allKeys]) if (![order containsObject:m]) [order addObject:m];
    for (NSString *m in order) {
        NSArray *a = [byMuscle objectForKey:m];
        if ([a count]) [secs addObject:[NSDictionary dictionaryWithObjectsAndKeys:GL(m), @"title", a, @"items", nil]];
    }
    _sections = secs;
    [self.table reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return (NSInteger)[_sections count]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[[[_sections objectAtIndex:(NSUInteger)s] objectForKey:@"items"] count]; }
- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }
- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSDictionary *sec = [_sections objectAtIndex:(NSUInteger)s];
    return SLHeaderForTitle([sec objectForKey:@"title"], [NSString stringWithFormat:@"%lu", (unsigned long)[[sec objectForKey:@"items"] count]]);
}

- (NSDictionary *)exerciseAt:(NSIndexPath *)ip
{
    return [[[_sections objectAtIndex:(NSUInteger)ip.section] objectForKey:@"items"] objectAtIndex:(NSUInteger)ip.row];
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"ex"];
    NSDictionary *e = [self exerciseAt:ip];
    c.textLabel.text = [[SLStore shared] displayNameForExercise:e];
    NSString *eq = [e objectForKey:@"equip"];
    c.detailTextLabel.text = eq ? GL(eq) : @"";
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    [_search resignFirstResponder];
    [self didSelectExercise:[self exerciseAt:ip]];
}

- (void)didSelectExercise:(NSDictionary *)ex
{
    [self.delegate picker:self didPickExerciseId:[ex objectForKey:@"id"]];
}

- (void)searchBar:(UISearchBar *)sb textDidChange:(NSString *)text
{
    _query = [text copy];
    [self reloadList];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)sb { [sb resignFirstResponder]; }

/* ---------- własne ćwiczenie ---------- */

- (void)addCustom
{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Nowe ćwiczenie") message:GL(@"Podaj nazwę ćwiczenia") delegate:self
                                      cancelButtonTitle:GL(@"Anuluj") otherButtonTitles:GL(@"Dalej"), nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    [a textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [a show];
}

- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i
{
    if (i == a.cancelButtonIndex) return;
    NSString *name = [[a textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([name length] == 0) return;
    SLMuscleChooser *mc = [[SLMuscleChooser alloc] initWithStyle:UITableViewStylePlain];
    mc.exerciseName = name;
    __weak SLPickerController *me = self;
    mc.onChoose = ^(NSString *muscle) {
        [[SLStore shared] addCustomExerciseNamed:name muscle:muscle];
        [me.navigationController popToViewController:me animated:YES];
        [me reloadList];
    };
    [self.navigationController pushViewController:mc animated:YES];
}

@end
