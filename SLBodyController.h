#import <UIKit/UIKit.h>

/* Pomiary ciała (waga, obwody) i zdjęcia postępów. */

@interface SLMeasuresController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface SLMeasureDetailController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
- (id)initWithType:(NSInteger)type;
@end

@interface SLPhotosController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@interface SLPhotoViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>
- (id)initWithPhotoId:(NSString *)pid;
@end
