#import "AppDelegate.h"
#import "SLStore.h"
#import "SLTheme.h"
#import "SLWorkoutController.h"
#import "SLHistoryController.h"
#import "SLExercisesController.h"
#import "SLSettingsController.h"

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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SLStore shared];
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];

    _workout = [[SLWorkoutController alloc] init];
    NSArray *controllers = [NSArray arrayWithObjects:
        [self navWith:_workout title:@"Trening" kind:0],
        [self navWith:[[SLHistoryController alloc] init] title:@"Historia" kind:1],
        [self navWith:[[SLExercisesController alloc] init] title:@"Ćwiczenia" kind:2],
        [self navWith:[[SLSettingsController alloc] init] title:@"Ustawienia" kind:3], nil];
    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = controllers;
    SLStyleTabBar(tabs.tabBar);
    self.window.rootViewController = tabs;
    [self.window makeKeyAndVisible];

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
