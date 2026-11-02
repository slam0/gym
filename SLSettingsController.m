#import "SLSettingsController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"

@implementation SLChoiceController
{
    UITableView *_table;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 44;
    SLStyleTable(_table);
    [self.view addSubview:_table];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[self.titles count]; }

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"choice"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"choice"];
    c.textLabel.text = [self.titles objectAtIndex:(NSUInteger)ip.row];
    c.imageView.image = ip.row < (NSInteger)[self.images count] ? [self.images objectAtIndex:(NSUInteger)ip.row] : nil;
    c.accessoryType = ip.row == self.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;     /* standardowy ptaszek */
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    if (ip.row == self.selected) return;
    self.selected = ip.row;
    [t reloadData];
    if (self.onChoose) self.onChoose(ip.row);
}

@end

/* ---------------------------------------------------------------------- */

@interface SLSettingsController ()
{
    UITableView *_table;
}
@end

@implementation SLSettingsController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Ustawienia");
    return self;
}

static const NSInteger kRests[] = { 0, 30, 45, 60, 90, 120, 180, 240 };
#define NRESTS 8

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    SLStyleTable(_table);
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [_table reloadData]; }

/* sekcje: 0 Wygląd, 1 Trening, 2 Dane, 3 O aplikacji */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 4; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    return s == 3 ? 4 : 2;
}

- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s
{
    NSArray *n = [NSArray arrayWithObjects:@"Wygląd", @"Trening", @"Dane", @"O aplikacji", nil];
    return GL([n objectAtIndex:(NSUInteger)s]);
}

- (UITableViewCell *)cellWithStyle:(UITableViewCellStyle)style identifier:(NSString *)ident table:(UITableView *)t
{
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:ident];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:ident];
    c.accessoryType = UITableViewCellAccessoryNone;
    c.accessoryView = nil;
    c.imageView.image = nil;
    c.detailTextLabel.text = nil;
    return c;
}

- (void)unitChanged:(UISegmentedControl *)sc
{
    [SLStore shared].units = sc.selectedSegmentIndex;
}

- (NSString *)restTitle:(NSInteger)sec
{
    return sec == 0 ? GL(@"Wyłączona") : [NSString stringWithFormat:GL(@"%ld s"), (long)sec];
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLStore *st = [SLStore shared];
    UITableViewCell *c;
    if (ip.section == 0) {
        c = [self cellWithStyle:UITableViewCellStyleValue1 identifier:@"v1" table:t];
        c.selectionStyle = UITableViewCellSelectionStyleBlue;
        c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (ip.row == 0) {
            c.textLabel.text = GL(@"Język");
            c.detailTextLabel.text = SLLanguageSettingName(SLLanguageSetting());
        } else {
            c.textLabel.text = GL(@"Motyw");
            c.detailTextLabel.text = SLThemeName(SLCurrentTheme());
            c.imageView.image = SLThemeSwatch(SLCurrentTheme());
        }
    } else if (ip.section == 1) {
        if (ip.row == 0) {
            c = [self cellWithStyle:UITableViewCellStyleDefault identifier:@"unit" table:t];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            c.textLabel.text = GL(@"Jednostka ciężaru");
            UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:GL(@"kg"), GL(@"lb"), nil]];
            sc.frame = CGRectMake(0, 0, 100, 30);
            sc.selectedSegmentIndex = st.units == 1 ? 1 : 0;
            [sc addTarget:self action:@selector(unitChanged:) forControlEvents:UIControlEventValueChanged];
            SLStyleSegmented(sc);
            c.accessoryView = sc;
        } else {
            c = [self cellWithStyle:UITableViewCellStyleValue1 identifier:@"v1" table:t];
            c.selectionStyle = UITableViewCellSelectionStyleBlue;
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            c.textLabel.text = GL(@"Przerwa między seriami");
            c.detailTextLabel.text = [self restTitle:st.restSeconds];
        }
    } else if (ip.section == 2) {
        if (ip.row == 0) {
            c = [self cellWithStyle:UITableViewCellStyleSubtitle identifier:@"sub" table:t];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            c.textLabel.text = GL(@"Kopia zapasowa");
            c.detailTextLabel.text = GL(@"Plik silka.json jest w iTunes → Aplikacje → Udostępnianie plików");
            c.detailTextLabel.numberOfLines = 2;
        } else {
            c = [self cellWithStyle:UITableViewCellStyleDefault identifier:@"danger" table:t];
            c.selectionStyle = UITableViewCellSelectionStyleBlue;
            c.textLabel.text = GL(@"Usuń wszystkie dane");
            c.textLabel.textAlignment = NSTextAlignmentCenter;
            c.textLabel.textColor = SLDangerColor();
        }
    } else {
        if (ip.row < 2) {
            c = [self cellWithStyle:UITableViewCellStyleValue1 identifier:@"v1" table:t];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            if (ip.row == 0) {
                c.textLabel.text = GL(@"Wersja");
                c.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            } else {
                c.textLabel.text = GL(@"Autor");
                c.detailTextLabel.text = @"nazar0vsky-slam0";
            }
        } else {
            c = [self cellWithStyle:UITableViewCellStyleSubtitle identifier:@"sub" table:t];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            c.detailTextLabel.numberOfLines = 2;
            if (ip.row == 2) {
                c.textLabel.text = GL(@"Baza ćwiczeń");
                c.detailTextLabel.text = GL(@"free-exercise-db (domena publiczna), własne tłumaczenia");
            } else {
                c.textLabel.text = GL(@"Dane");
                c.detailTextLabel.text = GL(@"Zapisane tylko w twoim telefonie");
            }
        }
    }
    return c;
}

- (CGFloat)tableView:(UITableView *)t heightForRowAtIndexPath:(NSIndexPath *)ip
{
    BOOL tall = (ip.section == 2 && ip.row == 0) || (ip.section == 3 && ip.row >= 2);
    return tall ? 62 : 44;
}

- (void)pushChoice:(NSArray *)titles images:(NSArray *)images selected:(NSInteger)sel title:(NSString *)title handler:(void (^)(NSInteger))handler
{
    SLChoiceController *cc = [[SLChoiceController alloc] init];
    cc.title = title;
    cc.titles = titles;
    cc.images = images;
    cc.selected = sel;
    cc.onChoose = handler;
    [self.navigationController pushViewController:cc animated:YES];
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    SLStore *st = [SLStore shared];
    if (ip.section == 0 && ip.row == 0) {
        NSMutableArray *names = [NSMutableArray array];
        for (NSInteger i = 0; i < 4; i++) [names addObject:SLLanguageSettingName(i)];
        [self pushChoice:names images:nil selected:SLLanguageSetting() title:GL(@"Język") handler:^(NSInteger i) { SLSetLanguageSetting(i); }];
    } else if (ip.section == 0 && ip.row == 1) {
        NSMutableArray *names = [NSMutableArray array], *imgs = [NSMutableArray array];
        for (NSInteger i = 0; i < SLThemeCount(); i++) { [names addObject:SLThemeName(i)]; [imgs addObject:SLThemeSwatch(i)]; }
        [self pushChoice:names images:imgs selected:SLCurrentTheme() title:GL(@"Motyw") handler:^(NSInteger i) { SLSetTheme(i); }];
    } else if (ip.section == 1 && ip.row == 1) {
        NSMutableArray *names = [NSMutableArray array];
        NSInteger idx = 0;
        for (NSInteger i = 0; i < NRESTS; i++) {
            [names addObject:[self restTitle:kRests[i]]];
            if (kRests[i] == st.restSeconds) idx = i;
        }
        [self pushChoice:names images:nil selected:idx title:GL(@"Przerwa między seriami") handler:^(NSInteger i) {
            [SLStore shared].restSeconds = kRests[i];
        }];
    } else if (ip.section == 2 && ip.row == 1) {
        UIActionSheet *s = [[UIActionSheet alloc] initWithTitle:GL(@"Usunąć wszystkie treningi i dane? Tego nie da się cofnąć.")
                                                       delegate:self cancelButtonTitle:GL(@"Anuluj") destructiveButtonTitle:GL(@"Usuń wszystko") otherButtonTitles:nil];
        [s showFromTabBar:self.tabBarController.tabBar];
    }
}

- (void)actionSheet:(UIActionSheet *)s clickedButtonAtIndex:(NSInteger)i
{
    if (i == s.destructiveButtonIndex) {
        [[SLStore shared] clearAll];
        [_table reloadData];
    }
}

@end
