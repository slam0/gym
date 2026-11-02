#import "SLHomeController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLViews.h"

@interface SLHomeController ()
{
    UIScrollView *_scroll;
    SLStatView *_countView, *_timeView, *_volumeView;
    UILabel *_detail;
    UIButton *_newButton;
    UIButton *_repeatButton;
    UILabel *_last;
}
@end

@implementation SLHomeController

- (id)init
{
    if ((self = [super init])) self.title = GL(@"Główna");
    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (UILabel *)labelAt:(CGRect)f size:(CGFloat)size bold:(BOOL)bold color:(UIColor *)color
{
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = color;
    l.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    l.textAlignment = NSTextAlignmentCenter;
    SLStyleShadow(l);
    [_scroll addSubview:l];
    return l;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    _scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scroll.contentSize = CGSizeMake(320, 400);
    _scroll.alwaysBounceVertical = YES;
    [self.view addSubview:_scroll];

    UILabel *title = [self labelAt:CGRectMake(20, 14, 280, 34) size:28 bold:YES color:SLTextColor()];
    title.text = @"Gym";
    UILabel *sub = [self labelAt:CGRectMake(20, 46, 280, 18) size:13 bold:NO color:SLSubtleColor()];
    sub.text = GL(@"Twoje treningi w liczbach");

    _countView  = [[SLStatView alloc] initWithFrame:CGRectMake(10, 76, 96, 76)];
    _timeView   = [[SLStatView alloc] initWithFrame:CGRectMake(112, 76, 96, 76)];
    _volumeView = [[SLStatView alloc] initWithFrame:CGRectMake(214, 76, 96, 76)];
    _countView.caption = GL(@"Treningi");
    _timeView.caption = GL(@"Czas");
    _volumeView.caption = GL(@"Objętość");
    [_scroll addSubview:_countView];
    [_scroll addSubview:_timeView];
    [_scroll addSubview:_volumeView];

    _detail = [self labelAt:CGRectMake(10, 158, 300, 18) size:13 bold:NO color:SLSubtleColor()];

    _newButton = SLGelButton(GL(@"Nowy trening"), 0, CGRectMake(20, 192, 280, 58));
    _newButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [_newButton addTarget:self action:@selector(newTapped) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:_newButton];

    _repeatButton = SLGelButton(GL(@"Powtórz poprzedni trening"), 1, CGRectMake(20, 262, 280, 46));
    [_repeatButton addTarget:self action:@selector(repeatTapped) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:_repeatButton];

    _last = [self labelAt:CGRectMake(20, 318, 280, 56) size:13 bold:NO color:SLSubtleColor()];
    _last.numberOfLines = 3;

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
    _countView.value = [NSString stringWithFormat:@"%ld", n];
    _timeView.value = SLLongDuration([[t objectForKey:@"seconds"] doubleValue]);
    _volumeView.value = SLBigWeightString([[t objectForKey:@"volume"] doubleValue]);
    long sets = [[t objectForKey:@"sets"] longValue], reps = [[t objectForKey:@"reps"] longValue];
    _detail.text = n > 0 ? [NSString stringWithFormat:@"%@ · %@", SLCountString(sets, SLNounSet),
                            SLCountString(reps, SLNounRep)]
                         : GL(@"Zacznij pierwszy trening, a tu pojawią się twoje liczby.");

    NSDictionary *active = [st active];
    NSArray *ws = [st workouts];
    if (active) {
        [_newButton setTitle:GL(@"Wróć do treningu") forState:UIControlStateNormal];
        _repeatButton.hidden = YES;
        _last.text = GL(@"Masz trwający trening. Dokończ go albo zakończ w zakładce Trening.");
    } else {
        [_newButton setTitle:GL(@"Nowy trening") forState:UIControlStateNormal];
        _repeatButton.hidden = [ws count] == 0;
        if ([ws count]) {
            NSDictionary *w = [ws objectAtIndex:0];
            _last.text = [NSString stringWithFormat:GL(@"Poprzedni trening: %@\n%@, %@"),
                          SLDateString([[w objectForKey:@"start"] doubleValue]),
                          SLCountString([SLStore doneSetsInWorkout:w], SLNounSet),
                          SLWeightString([SLStore volumeOfWorkout:w])];
        } else {
            _last.text = @"";
        }
    }
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
