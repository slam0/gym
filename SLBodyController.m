#import "SLBodyController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"
#import "sl_core.h"

/* typy pomiarów: 0 waga (kg, w jednostce z ustawień), reszta w cm */
static NSString *SLMeasureName(NSInteger type)
{
    switch (type) {
        case 0: return GL(@"Waga ciała");
        case 1: return GL(@"Biceps");
        case 2: return GL(@"Klatka piersiowa");
        case 3: return GL(@"Talia");
        case 4: return GL(@"Biodra");
        default: return GL(@"Udo");
    }
}

static NSString *SLMeasureValueString(NSInteger type, double v)
{
    return type == 0 ? SLWeightString(v) : [NSString stringWithFormat:@"%@ cm", SLNumberString(v)];
}

/* wartość w jednostce wyświetlania (waga: kg albo lb) */
static double SLMeasureDisplay(NSInteger type, double v)
{
    return (type == 0 && [SLStore shared].units == 1) ? sl_kg_to_lb(v) : v;
}

#define NMEASURES 6

/* ====================================================================== */

@interface SLMeasuresController ()
{
    UITableView *_table;
}
@end

@implementation SLMeasuresController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Pomiary ciała");
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
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_table reloadData];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return NMEASURES; }

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"m"];
    c.textLabel.text = SLMeasureName(ip.row);
    c.textLabel.font = [UIFont boldSystemFontOfSize:17];
    NSArray *ms = [[SLStore shared] measuresOfType:ip.row];
    if ([ms count]) {
        NSDictionary *m = [ms objectAtIndex:0];
        c.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", SLMeasureValueString(ip.row, [[m objectForKey:@"v"] doubleValue]),
                                  SLDateString([[m objectForKey:@"d"] doubleValue])];
    } else {
        c.detailTextLabel.text = GL(@"Brak pomiarów");
    }
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    [self.navigationController pushViewController:[[SLMeasureDetailController alloc] initWithType:ip.row] animated:YES];
}

@end

/* ====================================================================== */

@interface SLMeasureDetailController ()
{
    NSInteger _type;
    NSArray *_ms;            /* najnowsze pierwsze */
    UITableView *_table;
    SLChartView *_chart;
}
@end

@implementation SLMeasureDetailController

- (id)initWithType:(NSInteger)type
{
    if ((self = [super init])) {
        _type = type;
        self.title = SLMeasureName(type);
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
    _table.rowHeight = 44;
    _table.allowsSelection = NO;
    SLStyleTable(_table);

    UIView *head = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
    _chart = [[SLChartView alloc] initWithFrame:CGRectMake(10, 12, 300, 172)];
    [head addSubview:_chart];
    UIButton *add = SLGelButton(GL(@"+ Dodaj pomiar"), 0, CGRectMake(15, 194, 290, 46));
    [add addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
    [head addSubview:add];
    _table.tableHeaderView = head;
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

- (void)reload
{
    _ms = [[SLStore shared] measuresOfType:_type];
    NSMutableArray *vals = [NSMutableArray array], *lbs = [NSMutableArray array];
    NSArray *chrono = [[_ms reverseObjectEnumerator] allObjects];
    NSUInteger from = [chrono count] > 20 ? [chrono count] - 20 : 0;
    for (NSUInteger i = from; i < [chrono count]; i++)
        [vals addObject:[NSNumber numberWithDouble:SLMeasureDisplay(_type, [[[chrono objectAtIndex:i] objectForKey:@"v"] doubleValue])]];
    if ([chrono count]) {
        [lbs addObject:SLShortDateString([[[chrono objectAtIndex:from] objectForKey:@"d"] doubleValue])];
        if ([chrono count] - from > 1) [lbs addObject:SLShortDateString([[[chrono lastObject] objectForKey:@"d"] doubleValue])];
    }
    _chart.values = vals;
    _chart.labels = lbs;
    [_table reloadData];
}

- (void)addTapped
{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:SLMeasureName(_type)
        message:(_type == 0 ? [NSString stringWithFormat:GL(@"Podaj wagę (%@)"), SLUnitName()] : GL(@"Podaj wartość (cm)"))
        delegate:self cancelButtonTitle:GL(@"Anuluj") otherButtonTitles:GL(@"Zapisz"), nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *f = [a textFieldAtIndex:0];
    f.keyboardType = UIKeyboardTypeDecimalPad;
    if ([_ms count]) f.text = SLNumberString(SLMeasureDisplay(_type, [[[_ms objectAtIndex:0] objectForKey:@"v"] doubleValue]));
    [a show];
}

- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i
{
    if (i == a.cancelButtonIndex) return;
    double v = SLParseNumber([a textFieldAtIndex:0].text);
    if (v <= 0 || v > 1000) return;
    if (_type == 0) v = SLKgFromDisplay(v);
    [[SLStore shared] addMeasure:v type:_type];
    [self reload];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[_ms count]; }

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 26; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSString *right = nil;
    if ([_ms count] >= 2) {
        double d = [[[_ms objectAtIndex:0] objectForKey:@"v"] doubleValue] - [[[_ms lastObject] objectForKey:@"v"] doubleValue];
        double disp = SLMeasureDisplay(_type, d < 0 ? -d : d);
        right = [NSString stringWithFormat:@"%@%@ %@", d < 0 ? @"−" : @"+", SLNumberString(disp), _type == 0 ? SLUnitName() : @"cm"];
    }
    return SLHeaderForTitle([_ms count] ? GL(@"Historia pomiarów") : GL(@"Brak pomiarów"), right);
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"r"];
    NSDictionary *m = [_ms objectAtIndex:(NSUInteger)ip.row];
    c.textLabel.text = [NSString stringWithFormat:@"%@   ·   %@", SLMeasureValueString(_type, [[m objectForKey:@"v"] doubleValue]),
                        SLDateString([[m objectForKey:@"d"] doubleValue])];
    c.textLabel.font = [UIFont boldSystemFontOfSize:15];
    c.detailTextLabel.text = nil;
    return c;
}

- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (NSString *)tableView:(UITableView *)t titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)ip { return GL(@"Usuń"); }

- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip
{
    if (style != UITableViewCellEditingStyleDelete) return;
    [[SLStore shared] deleteMeasureWithId:[[_ms objectAtIndex:(NSUInteger)ip.row] objectForKey:@"id"]];
    [self reload];
}

@end

/* ====================================================================== */
#pragma mark - zdjęcia postępów

@interface SLPhotosController ()
{
    UITableView *_table;
    NSArray *_photos;
    UILabel *_empty;
}
@end

@implementation SLPhotosController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Zdjęcia postępów");
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
    _table.rowHeight = 72;
    SLStyleTable(_table);
    [self.view addSubview:_table];
    _empty = [[UILabel alloc] initWithFrame:CGRectMake(30, 120, 260, 80)];
    _empty.backgroundColor = [UIColor clearColor];
    _empty.numberOfLines = 3;
    _empty.textAlignment = NSTextAlignmentCenter;
    _empty.font = [UIFont systemFontOfSize:16];
    _empty.textColor = SLSubtleColor();
    _empty.text = GL(@"Dotknij +, żeby dodać pierwsze zdjęcie sylwetki.");
    [self.view addSubview:_empty];
    self.navigationItem.rightBarButtonItem = SLBarButton(@"+", self, @selector(addTapped));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

- (void)reload
{
    _photos = [[SLStore shared] photos];
    _empty.hidden = [_photos count] > 0;
    _table.hidden = [_photos count] == 0;
    [_table reloadData];
}

- (void)addTapped
{
    BOOL cam = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    UIActionSheet *s = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if (cam) [s addButtonWithTitle:GL(@"Zrób zdjęcie")];
    [s addButtonWithTitle:GL(@"Wybierz z biblioteki")];
    s.cancelButtonIndex = [s addButtonWithTitle:GL(@"Anuluj")];
    s.tag = cam ? 1 : 0;
    [s showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)s clickedButtonAtIndex:(NSInteger)i
{
    if (i == s.cancelButtonIndex) return;
    BOOL camAvailable = s.tag == 1;
    UIImagePickerControllerSourceType src = (camAvailable && i == 0) ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    UIImagePickerController *p = [[UIImagePickerController alloc] init];
    p.sourceType = src;
    p.delegate = self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (img) {
        if (![[SLStore shared] addPhotoWithImage:img]) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:GL(@"Nie udało się zapisać zdjęcia") message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show];
        }
    }
    [self reload];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return (NSInteger)[_photos count]; }

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    SLCell *c = [SLCell cellForTable:t identifier:@"f"];
    NSDictionary *p = [_photos objectAtIndex:(NSUInteger)ip.row];
    c.imageView.image = [UIImage imageWithContentsOfFile:[[SLStore shared] photoPathForId:[p objectForKey:@"id"] thumb:YES]];
    c.imageView.contentMode = UIViewContentModeScaleAspectFill;
    c.imageView.clipsToBounds = YES;
    c.textLabel.text = SLDateString([[p objectForKey:@"d"] doubleValue]);
    c.textLabel.font = [UIFont boldSystemFontOfSize:16];
    c.detailTextLabel.text = nil;
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:YES];
    NSString *pid = [[_photos objectAtIndex:(NSUInteger)ip.row] objectForKey:@"id"];
    [self.navigationController pushViewController:[[SLPhotoViewController alloc] initWithPhotoId:pid] animated:YES];
}

- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (NSString *)tableView:(UITableView *)t titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)ip { return GL(@"Usuń"); }

- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip
{
    if (style != UITableViewCellEditingStyleDelete) return;
    [[SLStore shared] deletePhotoWithId:[[_photos objectAtIndex:(NSUInteger)ip.row] objectForKey:@"id"]];
    [self reload];
}

@end

/* ====================================================================== */

@interface SLPhotoViewController ()
{
    NSString *_pid;
    UIScrollView *_scroll;
    UIImageView *_image;
}
@end

@implementation SLPhotoViewController

- (id)initWithPhotoId:(NSString *)pid
{
    if ((self = [super init])) _pid = [pid copy];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    _scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scroll.delegate = self;
    _scroll.minimumZoomScale = 1.0f;
    _scroll.maximumZoomScale = 4.0f;
    [self.view addSubview:_scroll];
    UIImage *img = [UIImage imageWithContentsOfFile:[[SLStore shared] photoPathForId:_pid thumb:NO]];
    _image = [[UIImageView alloc] initWithFrame:_scroll.bounds];
    _image.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.image = img;
    [_scroll addSubview:_image];
    for (NSDictionary *p in [[SLStore shared] photos])
        if ([[p objectForKey:@"id"] isEqual:_pid]) self.title = SLShortDateString([[p objectForKey:@"d"] doubleValue]);
    self.navigationItem.rightBarButtonItem = SLBarButton(GL(@"Usuń"), self, @selector(deleteTapped));
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)s { return _image; }

- (void)deleteTapped
{
    UIActionSheet *s = [[UIActionSheet alloc] initWithTitle:GL(@"Usunąć to zdjęcie?") delegate:self cancelButtonTitle:GL(@"Anuluj")
                                     destructiveButtonTitle:GL(@"Usuń") otherButtonTitles:nil];
    [s showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)s clickedButtonAtIndex:(NSInteger)i
{
    if (i != s.destructiveButtonIndex) return;
    [[SLStore shared] deletePhotoWithId:_pid];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
