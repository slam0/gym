#import <UIKit/UIKit.h>

/* Wspólne widoki: komórki z połyskiem, nagłówki sekcji, wykres, pole liczby. */

@interface SLCell : UITableViewCell          /* podtytuł + błyszczące tło */
+ (SLCell *)cellForTable:(UITableView *)table identifier:(NSString *)ident;
@end

@interface SLSectionHeader : UIView
- (id)initWithTitle:(NSString *)title right:(NSString *)right;
@end

UIView *SLHeaderForTitle(NSString *title, NSString *right);

/* Wiersz serii w treningu: numer, ciężar, powtórzenia, "zrobione". */
@interface SLSetCell : UITableViewCell
@property (nonatomic, strong) UILabel *numLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *repsLabel;
@property (nonatomic, strong) UILabel *recordLabel;
@property (nonatomic, strong) UITextField *kgField;
@property (nonatomic, strong) UITextField *repsField;
@property (nonatomic, strong) UIButton *doneButton;
- (void)setDone:(BOOL)done;
@end

/* Prosty wykres liniowy (bez libm). */
@interface SLChartView : UIView
@property (nonatomic, copy) NSArray *values;     /* NSNumber w jednostce wyświetlania */
@property (nonatomic, copy) NSArray *labels;     /* NSString dla pierwszego i ostatniego punktu */
@end

UIToolbar *SLKeyboardToolbar(id target, SEL doneAction);
UIImage *SLCheckImage(BOOL on);
