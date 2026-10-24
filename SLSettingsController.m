#import "SLSettingsController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLViews.h"

@interface SLSettingsController ()
{
    UITableView *_table;
}
@end

@implementation SLSettingsController

- (id)init
{
    if ((self = [super init])) self.title = @"Ustawienia";
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 3; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    return s == 0 ? 2 : (s == 1 ? 2 : 4);
}

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSArray *n = [NSArray arrayWithObjects:@"Trening", @"Dane", @"O aplikacji", nil];
    return SLHeaderForTitle([n objectAtIndex:(NSUInteger)s], nil);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"s"];
    c.accessoryType = UITableViewCellAccessoryNone;
    c.selectionStyle = UITableViewCellSelectionStyleBlue;
    c.textLabel.textColor = SLTextColor();
    SLStore *st = [SLStore shared];
    if (ip.section == 0) {
        if (ip.row == 0) {
            c.textLabel.text = @"Jednostka ciężaru";
            c.detailTextLabel.text = st.units == 1 ? @"funty (lb) — dotknij, aby zmienić" : @"kilogramy (kg) — dotknij, aby zmienić";
        } else {
            c.textLabel.text = @"Przerwa między seriami";
            c.detailTextLabel.text = st.restSeconds == 0 ? @"wyłączona — dotknij, aby zmienić"
                : [NSString stringWithFormat:@"%ld s — dotknij, aby zmienić", (long)st.restSeconds];
        }
    } else if (ip.section == 1) {
        if (ip.row == 0) {
            c.textLabel.text = @"Kopia zapasowa";
            c.detailTextLabel.text = @"Plik silka.json jest w iTunes → Aplikacje → Udostępnianie plików";
            c.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            c.textLabel.text = @"Usuń wszystkie dane";
            c.textLabel.textColor = [UIColor colorWithRed:1.0f green:0.45f blue:0.45f alpha:1];
            c.detailTextLabel.text = @"Treningi, własne ćwiczenia i ustawienia";
        }
    } else {
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        switch (ip.row) {
            case 0: c.textLabel.text = @"Wersja"; c.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; break;
            case 1: c.textLabel.text = @"Autor"; c.detailTextLabel.text = @"nazar0vsky-slam0"; break;
            case 2: c.textLabel.text = @"Baza ćwiczeń"; c.detailTextLabel.text = @"free-exercise-db (domena publiczna), nazwy po polsku"; break;
            default: c.textLabel.text = @"Dane"; c.detailTextLabel.text = @"Zapisane tylko w twoim telefonie"; break;
        }
    }
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    SLStore *st = [SLStore shared];
    if (ip.section == 0 && ip.row == 0) {
        st.units = st.units == 1 ? 0 : 1;
        [t reloadData];
    } else if (ip.section == 0 && ip.row == 1) {
        NSInteger idx = 0;
        for (NSInteger i = 0; i < NRESTS; i++) if (kRests[i] == st.restSeconds) idx = i;
        st.restSeconds = kRests[(idx + 1) % NRESTS];
        [t reloadData];
    } else if (ip.section == 1 && ip.row == 1) {
        UIActionSheet *s = [[UIActionSheet alloc] initWithTitle:@"Usunąć wszystkie treningi i dane? Tego nie da się cofnąć."
                                                       delegate:self cancelButtonTitle:@"Anuluj" destructiveButtonTitle:@"Usuń wszystko" otherButtonTitles:nil];
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
