#import "SLWorkoutController.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLViews.h"
#import "sl_core.h"
#import <AudioToolbox/AudioToolbox.h>

@interface SLWorkoutController ()
{
    UITableView *_table;
    UIView *_startView;
    UILabel *_lastLabel;
    UIButton *_repeatButton;
    UIView *_restBar;
    UILabel *_restLabel;
    NSTimer *_timer;
    double _restEnd;            /* 0 = brak przerwy */
    NSInteger _restTotal;
    UILocalNotification *_restNote;
    UIToolbar *_kbBar;
    UIView *_footer;
    UILabel *_hint;
    NSInteger _pendingAction;   /* 1 = zakończ bez serii, 2 = anuluj */
}
@end

@implementation SLWorkoutController

- (id)init
{
    if ((self = [super init])) {
        self.title = @"Trening";
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
}

#pragma mark - widoki

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SLBackgroundColor();
    CGRect b = self.view.bounds;

    _table = [[UITableView alloc] initWithFrame:b style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    SLStyleTable(_table);
    [self.view addSubview:_table];

    [self buildFooter];
    [self buildStartView:b];
    [self buildRestBar:b];

    _kbBar = SLKeyboardToolbar(self, @selector(dismissKeyboard));
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(storeChanged:) name:SLStoreDidChangeNotification object:nil];
}

- (void)buildStartView:(CGRect)b
{
    _startView = [[UIView alloc] initWithFrame:b];
    _startView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _startView.backgroundColor = SLBackgroundColor();

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 280, 40)];
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textColor = SLTextColor();
    title.textAlignment = NSTextAlignmentCenter;
    title.shadowColor = [UIColor colorWithWhite:0 alpha:0.9f];
    title.shadowOffset = CGSizeMake(0, -1);
    title.text = @"Gym";
    [_startView addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 280, 22)];
    sub.backgroundColor = [UIColor clearColor];
    sub.font = [UIFont systemFontOfSize:15];
    sub.textColor = SLSubtleColor();
    sub.textAlignment = NSTextAlignmentCenter;
    sub.text = @"Dziennik treningowy";
    [_startView addSubview:sub];

    UIButton *start = SLGelButton(@"Rozpocznij trening", 0, CGRectMake(30, 130, 260, 56));
    start.titleLabel.font = [UIFont boldSystemFontOfSize:21];
    [start addTarget:self action:@selector(startTapped) forControlEvents:UIControlEventTouchUpInside];
    [_startView addSubview:start];

    _repeatButton = SLGelButton(@"Powtórz ostatni trening", 1, CGRectMake(30, 200, 260, 46));
    [_repeatButton addTarget:self action:@selector(repeatTapped) forControlEvents:UIControlEventTouchUpInside];
    [_startView addSubview:_repeatButton];

    _lastLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 258, 280, 60)];
    _lastLabel.backgroundColor = [UIColor clearColor];
    _lastLabel.font = [UIFont systemFontOfSize:14];
    _lastLabel.textColor = SLSubtleColor();
    _lastLabel.textAlignment = NSTextAlignmentCenter;
    _lastLabel.numberOfLines = 3;
    [_startView addSubview:_lastLabel];
    [self.view addSubview:_startView];
}

- (void)buildFooter
{
    _footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 190)];
    UIButton *add = SLGelButton(@"+ Dodaj ćwiczenie", 1, CGRectMake(15, 16, 290, 46));
    [add addTarget:self action:@selector(addExerciseTapped) forControlEvents:UIControlEventTouchUpInside];
    [_footer addSubview:add];
    UIButton *fin = SLGelButton(@"Zakończ trening", 3, CGRectMake(15, 76, 290, 46));
    [fin addTarget:self action:@selector(finishTapped) forControlEvents:UIControlEventTouchUpInside];
    [_footer addSubview:fin];
    UIButton *cancel = SLGelButton(@"Anuluj trening", 2, CGRectMake(15, 134, 290, 40));
    cancel.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [_footer addSubview:cancel];
    _table.tableFooterView = _footer;

    _hint = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 280, 70)];
    _hint.backgroundColor = [UIColor clearColor];
    _hint.numberOfLines = 3;
    _hint.textAlignment = NSTextAlignmentCenter;
    _hint.font = [UIFont systemFontOfSize:15];
    _hint.textColor = SLSubtleColor();
    _hint.text = @"Dodaj pierwsze ćwiczenie, żeby zacząć wpisywać serie.";
}

- (void)buildRestBar:(CGRect)b
{
    _restBar = [[UIView alloc] initWithFrame:CGRectMake(0, b.size.height - 48, b.size.width, 48)];
    _restBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _restBar.backgroundColor = [UIColor colorWithRed:0.10f green:0.11f blue:0.13f alpha:0.96f];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 2)];
    line.backgroundColor = SLAccentColor();
    line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_restBar addSubview:line];
    _restLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 120, 34)];
    _restLabel.backgroundColor = [UIColor clearColor];
    _restLabel.textColor = SLTextColor();
    _restLabel.font = [UIFont boldSystemFontOfSize:20];
    [_restBar addSubview:_restLabel];
    NSArray *titles = [NSArray arrayWithObjects:@"-15", @"+15", @"Pomiń", nil];
    CGFloat xs[3] = { 134, 190, 246 };
    CGFloat ws[3] = { 52, 52, 66 };
    for (int i = 0; i < 3; i++) {
        UIButton *bt = SLGelButton([titles objectAtIndex:(NSUInteger)i], i == 2 ? 2 : 1, CGRectMake(xs[i], 9, ws[i], 32));
        bt.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        bt.tag = i;
        [bt addTarget:self action:@selector(restButton:) forControlEvents:UIControlEventTouchUpInside];
        [_restBar addSubview:bt];
    }
    _restBar.hidden = YES;
    [self.view addSubview:_restBar];
}

#pragma mark - cykl życia

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)storeChanged:(NSNotification *)n
{
    /* historia mogła się zmienić (np. usunięty trening): odśwież tekst startowy */
    if (self.isViewLoaded && !_startView.hidden) [self refreshStartView];
}

- (void)refresh
{
    BOOL active = [[SLStore shared] active] != nil;
    _startView.hidden = active;
    _table.hidden = !active;
    self.navigationItem.rightBarButtonItem = active ? SLBarButton(@"Zakończ", self, @selector(finishTapped)) : nil;
    if (active) {
        [_table reloadData];
        _table.tableHeaderView = ([[[SLStore shared] active] objectForKey:@"entries"] && [[[[SLStore shared] active] objectForKey:@"entries"] count] == 0) ? _hint : nil;
        [self updateTitle];
    } else {
        [self refreshStartView];
        self.navigationItem.title = @"Trening";
        [self hideRest];
    }
}

- (void)refreshStartView
{
    NSArray *ws = [[SLStore shared] workouts];
    if ([ws count]) {
        NSDictionary *w = [ws objectAtIndex:0];
        _lastLabel.text = [NSString stringWithFormat:@"Ostatni trening: %@\n%@, %@",
                           SLDateString([[w objectForKey:@"start"] doubleValue]),
                           SLCountString([SLStore doneSetsInWorkout:w], @"seria", @"serie", @"serii"),
                           SLWeightString([SLStore volumeOfWorkout:w])];
        _repeatButton.hidden = NO;
    } else {
        _lastLabel.text = @"Jeszcze nie masz zapisanych treningów.\nDotknij „Rozpocznij trening”.";
        _repeatButton.hidden = YES;
    }
}

- (void)updateTitle
{
    NSDictionary *a = [[SLStore shared] active];
    if (!a) return;
    long el = (long)([[NSDate date] timeIntervalSince1970] - [[a objectForKey:@"start"] doubleValue]);
    self.navigationItem.title = SLDurationString(el);
}

- (void)tick
{
    if ([[SLStore shared] active]) [self updateTitle];
    if (_restEnd > 0) {
        long left = (long)(_restEnd - [[NSDate date] timeIntervalSince1970] + 0.999);
        if (left <= 0) {
            [self restFinished];
        } else {
            _restLabel.text = [NSString stringWithFormat:@"Przerwa %@", SLDurationString(left)];
        }
    }
}

#pragma mark - start / koniec

- (void)startTapped
{
    [[SLStore shared] startWorkout];
    [self refresh];
}

- (void)repeatTapped
{
    NSArray *ws = [[SLStore shared] workouts];
    if (![ws count]) return;
    [[SLStore shared] startWorkoutRepeating:[ws objectAtIndex:0]];
    [self refresh];
}

- (void)finishTapped
{
    [self.view endEditing:YES];
    SLStore *st = [SLStore shared];
    if (![st active]) return;
    if (![st activeHasDoneSets]) {
        _pendingAction = 1;
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Brak wykonanych serii"
            message:@"Zaznacz serie jako zrobione (ptaszek po prawej) albo usuń ten trening."
            delegate:self cancelButtonTitle:@"Wróć" otherButtonTitles:@"Usuń trening", nil];
        [a show];
        return;
    }
    NSDictionary *w = [st active];
    NSString *summary = [NSString stringWithFormat:@"%@, %@, %@.",
                         SLCountString([SLStore exerciseCountInWorkout:w], @"ćwiczenie", @"ćwiczenia", @"ćwiczeń"),
                         SLCountString([SLStore doneSetsInWorkout:w], @"seria", @"serie", @"serii"),
                         SLWeightString([SLStore volumeOfWorkout:w])];
    [st finishActive];
    [self hideRest];
    [self refresh];
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Trening zapisany" message:summary delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
    if (self.tabBarController) self.tabBarController.selectedIndex = 2;
}

- (void)cancelTapped
{
    [self.view endEditing:YES];
    _pendingAction = 2;
    UIActionSheet *s = [[UIActionSheet alloc] initWithTitle:@"Usunąć ten trening? Wpisane serie przepadną."
                                                   delegate:self cancelButtonTitle:@"Wróć" destructiveButtonTitle:@"Usuń trening" otherButtonTitles:nil];
    [s showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)s clickedButtonAtIndex:(NSInteger)i
{
    if (i == s.destructiveButtonIndex && _pendingAction == 2) {
        [[SLStore shared] discardActive];
        [self hideRest];
        [self refresh];
    }
}

- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i
{
    if (_pendingAction == 1 && i != a.cancelButtonIndex) {
        [[SLStore shared] discardActive];
        [self hideRest];
        [self refresh];
    }
}

#pragma mark - dodawanie ćwiczeń

- (void)addExerciseTapped
{
    [self.view endEditing:YES];
    SLPickerController *p = [[SLPickerController alloc] init];
    p.delegate = self;
    p.navigationItem.leftBarButtonItem = SLBarButton(@"Anuluj", self, @selector(closePicker));
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:p];
    SLStyleNavigationBar(nav.navigationBar);
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)closePicker { [self dismissViewControllerAnimated:YES completion:nil]; }

- (void)picker:(SLPickerController *)picker didPickExerciseId:(NSString *)exId
{
    NSMutableDictionary *a = [[SLStore shared] active];
    if (a) [[SLStore shared] addExercise:exId toWorkout:a];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self refresh];
    NSInteger last = (NSInteger)[[a objectForKey:@"entries"] count] - 1;
    if (last >= 0) [_table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:last] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)removeEntry:(UIButton *)b
{
    [self.view endEditing:YES];
    NSMutableDictionary *a = [[SLStore shared] active];
    if (!a) return;
    [[SLStore shared] removeEntryAtIndex:(NSUInteger)b.tag fromWorkout:a];
    [self refresh];
}

#pragma mark - tabela

- (NSArray *)entries { return [[[SLStore shared] active] objectForKey:@"entries"]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return (NSInteger)[[self entries] count]; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s
{
    NSDictionary *e = [[self entries] objectAtIndex:(NSUInteger)s];
    return (NSInteger)[[e objectForKey:@"sets"] count] + 1;
}

- (CGFloat)tableView:(UITableView *)t heightForHeaderInSection:(NSInteger)s { return 34; }

- (UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s
{
    NSDictionary *e = [[self entries] objectAtIndex:(NSUInteger)s];
    UIView *h = SLHeaderForTitle([[SLStore shared] nameForExerciseId:[e objectForKey:@"ex"]], nil);
    h.frame = CGRectMake(0, 0, 320, 34);
    UIButton *x = [UIButton buttonWithType:UIButtonTypeCustom];
    x.frame = CGRectMake(268, 0, 52, 34);
    x.tag = s;
    [x setTitle:@"Usuń" forState:UIControlStateNormal];
    [x setTitleColor:SLSubtleColor() forState:UIControlStateNormal];
    x.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    x.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [x addTarget:self action:@selector(removeEntry:) forControlEvents:UIControlEventTouchUpInside];
    [h addSubview:x];
    return h;
}

- (CGFloat)tableView:(UITableView *)t heightForRowAtIndexPath:(NSIndexPath *)ip
{
    NSDictionary *e = [[self entries] objectAtIndex:(NSUInteger)ip.section];
    if ((NSUInteger)ip.row == [[e objectForKey:@"sets"] count]) return 40;
    return 56;
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip
{
    NSMutableDictionary *e = [[self entries] objectAtIndex:(NSUInteger)ip.section];
    NSArray *sets = [e objectForKey:@"sets"];
    if ((NSUInteger)ip.row == [sets count]) {
        SLCell *c = [SLCell cellForTable:t identifier:@"add"];
        c.textLabel.text = @"+ Dodaj serię";
        c.textLabel.textAlignment = NSTextAlignmentCenter;
        c.textLabel.textColor = SLAccentColor();
        c.textLabel.font = [UIFont boldSystemFontOfSize:15];
        c.detailTextLabel.text = nil;
        return c;
    }
    SLSetCell *c = (SLSetCell *)[t dequeueReusableCellWithIdentifier:@"set"];
    if (!c) {
        c = [[SLSetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"set"];
        c.kgField.delegate = self;
        c.repsField.delegate = self;
        c.kgField.inputAccessoryView = _kbBar;
        c.repsField.inputAccessoryView = _kbBar;
        [c.doneButton addTarget:self action:@selector(doneTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    NSDictionary *s = [sets objectAtIndex:(NSUInteger)ip.row];
    double kg = [[s objectForKey:@"kg"] doubleValue];
    int reps = [[s objectForKey:@"reps"] intValue];
    c.numLabel.text = [NSString stringWithFormat:@"%ld", (long)ip.row + 1];
    c.kgField.text = kg > 0 ? SLWeightNumber(kg) : @"";
    c.kgField.placeholder = @"0";
    c.repsField.text = reps > 0 ? [NSString stringWithFormat:@"%d", reps] : @"";
    c.repsField.placeholder = @"0";
    c.unitLabel.text = SLUnitName();
    BOOL done = [[s objectForKey:@"done"] boolValue];
    [c setDone:done];
    c.recordLabel.text = (done && [[s objectForKey:@"pr"] boolValue]) ? @"★ NOWY REKORD" : @"";
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip
{
    [t deselectRowAtIndexPath:ip animated:NO];
    NSDictionary *e = [[self entries] objectAtIndex:(NSUInteger)ip.section];
    if ((NSUInteger)ip.row == [[e objectForKey:@"sets"] count]) {
        [self.view endEditing:YES];
        [self addSetAt:ip.section];
    }
}

- (NSIndexPath *)pathForView:(UIView *)v
{
    UIView *x = v;
    while (x && ![x isKindOfClass:[UITableViewCell class]]) x = x.superview;
    return x ? [_table indexPathForCell:(UITableViewCell *)x] : nil;
}

#pragma mark - pola tekstowe

- (void)dismissKeyboard { [self.view endEditing:YES]; }

- (void)textFieldDidEndEditing:(UITextField *)tf
{
    NSIndexPath *ip = [self pathForView:tf];
    if (!ip) return;
    NSMutableDictionary *e = [[self entries] objectAtIndex:(NSUInteger)ip.section];
    NSMutableDictionary *s = [[e objectForKey:@"sets"] objectAtIndex:(NSUInteger)ip.row];
    SLSetCell *cell = (SLSetCell *)[_table cellForRowAtIndexPath:ip];
    if (tf == cell.kgField) {
        double kg = sl_round2(SLKgFromDisplay(SLParseNumber(tf.text)));
        if (kg < 0) kg = 0;
        [s setObject:[NSNumber numberWithDouble:kg] forKey:@"kg"];
    } else {
        int reps = [tf.text intValue];
        if (reps < 0) reps = 0;
        [s setObject:[NSNumber numberWithInt:reps] forKey:@"reps"];
    }
    [[SLStore shared] save];
}

- (BOOL)textField:(UITextField *)tf shouldChangeCharactersInRange:(NSRange)r replacementString:(NSString *)str
{
    if ([str length] == 0) return YES;
    NSString *res = [tf.text stringByReplacingCharactersInRange:r withString:str];
    if ([res length] > 7) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:(tf.keyboardType == UIKeyboardTypeNumberPad ? @"0123456789" : @"0123456789.,")];
    return [[str stringByTrimmingCharactersInSet:allowed] length] == 0;
}

#pragma mark - serie

- (void)addSetAt:(NSInteger)section
{
    NSMutableDictionary *e = [[self entries] objectAtIndex:(NSUInteger)section];
    [[SLStore shared] addSetToEntry:e];
    [_table reloadData];
}

- (void)doneTapped:(UIButton *)b
{
    [self.view endEditing:YES];
    NSIndexPath *ip = [self pathForView:b];
    if (!ip) return;
    NSMutableDictionary *a = [[SLStore shared] active];
    NSMutableDictionary *e = [[self entries] objectAtIndex:(NSUInteger)ip.section];
    NSMutableDictionary *s = [[e objectForKey:@"sets"] objectAtIndex:(NSUInteger)ip.row];
    BOOL wasDone = [[s objectForKey:@"done"] boolValue];
    if (wasDone) {
        [s setObject:[NSNumber numberWithBool:NO] forKey:@"done"];
        [s removeObjectForKey:@"pr"];
    } else {
        double kg = [[s objectForKey:@"kg"] doubleValue];
        int reps = [[s objectForKey:@"reps"] intValue];
        if (reps <= 0) {
            SLSetCell *cell = (SLSetCell *)[_table cellForRowAtIndexPath:ip];
            [cell.repsField becomeFirstResponder];
            return;
        }
        [s setObject:[NSNumber numberWithBool:YES] forKey:@"done"];
        double e1 = sl_e1rm(kg, reps);
        NSString *exId = [e objectForKey:@"ex"];
        double best = [[SLStore shared] bestE1RMForExercise:exId excludingWorkout:a];
        BOOL pr = (e1 > 0 && best > 0 && e1 > best + 0.0001);
        /* rekord tylko, jeśli to najlepsza seria także w tym treningu */
        if (pr) {
            for (NSDictionary *other in [e objectForKey:@"sets"]) {
                if (other == s || ![[other objectForKey:@"done"] boolValue]) continue;
                if (sl_e1rm([[other objectForKey:@"kg"] doubleValue], [[other objectForKey:@"reps"] intValue]) >= e1) { pr = NO; break; }
            }
        }
        if (pr) [s setObject:[NSNumber numberWithBool:YES] forKey:@"pr"]; else [s removeObjectForKey:@"pr"];
        if ([SLStore shared].restSeconds > 0) [self startRest:[SLStore shared].restSeconds];
    }
    [[SLStore shared] save];
    [_table reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - stoper przerwy

- (void)startRest:(NSInteger)seconds
{
    _restTotal = seconds;
    _restEnd = [[NSDate date] timeIntervalSince1970] + seconds;
    [self scheduleRestNotification];
    [self showRest];
    [self tick];
}

- (void)scheduleRestNotification
{
    [self cancelRestNotification];
    UILocalNotification *n = [[UILocalNotification alloc] init];
    n.fireDate = [NSDate dateWithTimeIntervalSince1970:_restEnd];
    n.alertBody = @"Koniec przerwy. Czas na kolejną serię!";
    n.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:n];
    _restNote = n;
}

- (void)cancelRestNotification
{
    if (_restNote) [[UIApplication sharedApplication] cancelLocalNotification:_restNote];
    _restNote = nil;
}

- (void)showRest
{
    if (!_restBar.hidden) return;
    _restBar.hidden = NO;
    UIEdgeInsets in = _table.contentInset;
    in.bottom = 48;
    _table.contentInset = in;
    _table.scrollIndicatorInsets = in;
}

- (void)hideRest
{
    _restEnd = 0;
    [self cancelRestNotification];
    _restBar.hidden = YES;
    UIEdgeInsets in = _table.contentInset;
    in.bottom = 0;
    _table.contentInset = in;
    _table.scrollIndicatorInsets = in;
}

- (void)restFinished
{
    [self hideRest];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)restDidEndInBackground
{
    if (_restEnd > 0 && [[NSDate date] timeIntervalSince1970] >= _restEnd - 1) [self hideRest];
}

- (void)restButton:(UIButton *)b
{
    if (b.tag == 2) { [self hideRest]; return; }
    _restEnd += (b.tag == 0 ? -15 : 15);
    if (_restEnd <= [[NSDate date] timeIntervalSince1970]) { [self hideRest]; return; }
    [self scheduleRestNotification];
    [self tick];
}

#pragma mark - klawiatura

- (void)keyboardWillShow:(NSNotification *)n
{
    if (!self.view.window) return;
    CGRect kb = [[[n userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat h = kb.size.height - 49.0f;       /* zakładki są pod klawiaturą */
    if (h < 0) h = 0;
    UIEdgeInsets in = _table.contentInset;
    in.bottom = h;
    _table.contentInset = in;
    _table.scrollIndicatorInsets = in;
    UIView *fr = nil;
    for (UITableViewCell *c in [_table visibleCells]) {
        if ([c isKindOfClass:[SLSetCell class]]) {
            SLSetCell *sc = (SLSetCell *)c;
            if ([sc.kgField isFirstResponder] || [sc.repsField isFirstResponder]) { fr = c; break; }
        }
    }
    NSIndexPath *ip = fr ? [_table indexPathForCell:(UITableViewCell *)fr] : nil;
    if (ip) [_table scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)n
{
    UIEdgeInsets in = _table.contentInset;
    in.bottom = _restBar.hidden ? 0 : 48;
    _table.contentInset = in;
    _table.scrollIndicatorInsets = in;
}

@end
