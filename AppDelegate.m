#import "AppDelegate.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLLang.h"
#import "SLWorkoutController.h"
#import "SLHistoryController.h"
#import "SLExercisesController.h"
#import "SLSettingsController.h"
#import "SLPlansController.h"
#import "SLProgressController.h"

@interface AppDelegate ()
{
    SLWorkoutController *_workout;
}
@end

@implementation AppDelegate

- (UINavigationController *)navWith:(UIViewController *)root title:(NSString *)title kind:(int)kind
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    SLStyleNavigationBar(nav.navigationBar);
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:SLTabIcon(kind) tag:kind];
    SLStyleTabItem(nav.tabBarItem, kind);
    return nav;
}

/* cały interfejs od zera: przy starcie oraz po zmianie motywu albo języka */
- (UITabBarController *)buildTabs
{
    _workout = [[SLWorkoutController alloc] init];
    /* Główna (liczby + trening) jest zakładką na środku: Historia, Ćwiczenia, GŁÓWNA, Plany, Postępy.
       Ustawienia otwiera przycisk po lewej na Głównej. */
    NSArray *controllers = [NSArray arrayWithObjects:
        [self navWith:[[SLHistoryController alloc] init] title:GL(@"Historia") kind:1],
        [self navWith:[[SLExercisesController alloc] init] title:GL(@"Ćwiczenia") kind:2],
        [self navWith:_workout title:GL(@"Główna") kind:4],
        [self navWith:[[SLPlansController alloc] init] title:GL(@"Plany") kind:5],
        [self navWith:[[SLProgressController alloc] init] title:GL(@"Postępy") kind:6], nil];
    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = controllers;
    tabs.selectedIndex = 2;                      /* start na Głównej */
    SLStyleTabBar(tabs.tabBar);
    return tabs;
}

- (void)appearanceChanged:(NSNotification *)n
{
    /* po wyjściu z obsługi dotknięcia, żeby nie usuwać kontrolera, który właśnie działa */
    [self performSelector:@selector(rebuildInterface) withObject:nil afterDelay:0.0];
}

- (void)rebuildInterface
{
    UITabBarController *old = (UITabBarController *)self.window.rootViewController;
    NSUInteger selected = [old isKindOfClass:[UITabBarController class]] ? old.selectedIndex : 2;
    /* ustawienia leżą na stosie Głównej: po zmianie motywu albo języka otwórz je z powrotem */
    BOOL settingsOpen = NO;
    if ([old isKindOfClass:[UITabBarController class]] && [old.viewControllers count] > 2) {
        UINavigationController *n = (UINavigationController *)[old.viewControllers objectAtIndex:2];
        settingsOpen = [n.topViewController isKindOfClass:[SLSettingsController class]];
    }
    [old dismissViewControllerAnimated:NO completion:nil];
    [_workout shutdown];
    UITabBarController *tabs = [self buildTabs];
    tabs.selectedIndex = selected;
    if (settingsOpen) [(UINavigationController *)[tabs.viewControllers objectAtIndex:2] pushViewController:[[SLSettingsController alloc] init] animated:NO];
    [UIView transitionWithView:self.window duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ self.window.rootViewController = tabs; } completion:nil];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SLStore shared];
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];

    self.window.rootViewController = [self buildTabs];
    [self.window makeKeyAndVisible];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appearanceChanged:) name:SLAppearanceDidChangeNotification object:nil];

    /* ekran powitalny: ten sam obraz co Default.png, przytrzymany chwilę i płynnie zgaszony */
    CGRect bounds = [[UIScreen mainScreen] bounds];
    UIImage *splash = [UIImage imageNamed:(bounds.size.height > 480.0f ? @"Default-568h" : @"Default")];
    if (splash) {
        UIImageView *cover = [[UIImageView alloc] initWithFrame:bounds];
        cover.image = splash;
        cover.contentMode = UIViewContentModeScaleAspectFill;
        cover.clipsToBounds = YES;
        cover.userInteractionEnabled = YES;
        [self.window addSubview:cover];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.4 animations:^{ cover.alpha = 0.0f; }
                             completion:^(BOOL finished) { [cover removeFromSuperview]; }];
        });
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application { [[SLStore shared] save]; }
- (void)applicationWillTerminate:(UIApplication *)application { [[SLStore shared] save]; }

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    /* przerwa skończyła się; w otwartej aplikacji wibruje stoper, w tle gra dźwięk powiadomienia */
    [_workout restDidEndInBackground];
}

@end
