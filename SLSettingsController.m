#import "SLSettingsController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"

/* ptaszek w kolorze motywu (systemowy jest ciemnoniebieski i na grafitowym tle słabo widać) */
static UIImage *SLTickImage(void)
{
    CGFloat s = 22.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s, s), NO, 0.0f);
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(3, 11.5f)];
    [p addLineToPoint:CGPointMake(8.5f, 17)];
    [p addLineToPoint:CGPointMake(19, 5)];
    p.lineWidth = 3.6f;
    p.lineCapStyle = kCGLineCapRound;
    p.lineJoinStyle = kCGLineJoinRound;
    [SLAccentColor() setStroke];
    [p stroke];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@implementation SLChoiceController
{
    UITableView *_table;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 52;
    SLStyleTable(_table);
    [self.view addSubview:_table];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[self.titles count]; }

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"choice"];
    c.textLabel.text = [self.titles objectAtIndex:(NSUInteger)ip.row];
    c.detailTextLabel.text = nil;
    c.imageView.image = ip.row < (NSInteger)[self.images count] ? [self.images objectAtIndex:(NSUInteger)ip.row] : nil;
    c.accessoryView = ip.row == self.selected ? [[UIImageView alloc] initWithImage:SLTickImage()] : nil;
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
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 52;
    SLStyleTable(_table);
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [_table reloadData]; }

/* sekcje: 0 Wygląd, 1 Trening, 2 Dane, 3 O aplikacji */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 4; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    return s == 0 ? 2 : (s == 1 ? 2 : (s == 2 ? 2 : 4));
}

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSArray *n = [NSArray arrayWithObjects:@"Wygląd", @"Trening", @"Dane", @"O aplikacji", nil];
    return SLHeaderForTitle(GL([n objectAtIndex:(NSUInteger)s]), nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"s"];
    c.accessoryType = UITableViewCellAccessoryNone;
    c.accessoryView = nil;
    c.imageView.image = nil;
    c.selectionStyle = UITableViewCellSelectionStyleBlue;
    c.textLabel.textColor = SLTextColor();
    SLStore *st = [SLStore shared];
    if (ip.section == 0) {
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
            c.textLabel.text = GL(@"Jednostka ciężaru");
            c.detailTextLabel.text = GL(st.units == 1 ? @"funty (lb) — dotknij, aby zmienić" : @"kilogramy (kg) — dotknij, aby zmienić");
        } else {
            c.textLabel.text = GL(@"Przerwa między seriami");
            c.detailTextLabel.text = st.restSeconds == 0 ? GL(@"wyłączona — dotknij, aby zmienić")
                : [NSString stringWithFormat:GL(@"%ld s — dotknij, aby zmienić"), (long)st.restSeconds];
        }
    } else if (ip.section == 2) {
        if (ip.row == 0) {
            c.textLabel.text = GL(@"Kopia zapasowa");
            c.detailTextLabel.text = GL(@"Plik silka.json jest w iTunes → Aplikacje → Udostępnianie plików");
            c.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            c.textLabel.text = GL(@"Usuń wszystkie dane");
            c.textLabel.textColor = SLRGB(SLP()->danger, 1);
            c.detailTextLabel.text = GL(@"Treningi, własne ćwiczenia i ustawienia");
        }
    } else {
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        switch (ip.row) {
            case 0: c.textLabel.text = GL(@"Wersja"); c.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; break;
            case 1: c.textLabel.text = GL(@"Autor"); c.detailTextLabel.text = @"nazar0vsky-slam0"; break;
            case 2: c.textLabel.text = GL(@"Baza ćwiczeń"); c.detailTextLabel.text = GL(@"free-exercise-db (domena publiczna), własne tłumaczenia"); break;
            default: c.textLabel.text = GL(@"Dane"); c.detailTextLabel.text = GL(@"Zapisane tylko w twoim telefonie"); break;
        }
    }
    return c;
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
    } else if (ip.section == 1 && ip.row == 0) {
        st.units = st.units == 1 ? 0 : 1;
        [t reloadData];
    } else if (ip.section == 1 && ip.row == 1) {
        NSInteger idx = 0;
        for (NSInteger i = 0; i < NRESTS; i++) if (kRests[i] == st.restSeconds) idx = i;
        st.restSeconds = kRests[(idx + 1) % NRESTS];
        [t reloadData];
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
