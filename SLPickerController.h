#import <UIKit/UIKit.h>

@class SLPickerController;

@protocol SLPickerDelegate <NSObject>
- (void)picker:(SLPickerController *)picker didPickExerciseId:(NSString *)exId;
@end

/* Lista ćwiczeń z wyszukiwarką, grupowana po partiach mięśni. Wybór → delegat. */
@interface SLPickerController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) id<SLPickerDelegate> delegate;
@property (nonatomic, strong) UITableView *table;
- (void)reloadList;
- (void)didSelectExercise:(NSDictionary *)ex;      /* do nadpisania */
@end
