#import <UIKit/UIKit.h>

/* Zakładka "Historia": lista zakończonych treningów i podgląd jednego z nich. */
@interface SLHistoryController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface SLWorkoutDetailController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (id)initWithWorkout:(NSDictionary *)workout;
@end
