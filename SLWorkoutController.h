#import <UIKit/UIKit.h>
#import "SLPickerController.h"

/* Zakładka "Trening": start, aktywny trening z seriami, stoper przerwy. */
@interface SLWorkoutController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SLPickerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
- (void)restDidEndInBackground;     /* wywoływane z AppDelegate po powiadomieniu */
@end
