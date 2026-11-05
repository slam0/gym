#import <UIKit/UIKit.h>

/* Zakładka "Postępy": podsumowanie tygodnia, kalendarz, rekordy, analiza partii mięśni, pomiary i zdjęcia. */
@interface SLProgressController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface SLCalendarController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface SLRecordsController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface SLAnalysisController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end
