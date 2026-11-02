#import <UIKit/UIKit.h>

/* Wspólne elementy: komórka z podtytułem (zwykła komórka UIKit), nagłówek sekcji list grupowanych,
   wiersz serii z polami liczb i przełącznikiem, wykres, miniatury ćwiczeń. */

@interface SLCell : UITableViewCell          /* styl Subtitle bez własnego rysowania */
+ (SLCell *)cellForTable:(UITableView *)table identifier:(NSString *)ident;
@end

/* Nagłówek sekcji w stylu list grupowanych iOS 6 (szary pogrubiony tekst z białym cieniem). */
@interface SLSectionHeader : UIView
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *rightLabel;
- (id)initWithTitle:(NSString *)title right:(NSString *)right;
@end

UIView *SLHeaderForTitle(NSString *title, NSString *right);
/* Stopka sekcji listy grupowanej (tekst wyśrodkowany, kolor zgodny z tłem motywu) i jej wysokość. */
UIView *SLFooterForText(NSString *text);
CGFloat SLFooterHeight(NSString *text);

/* Wiersz serii w treningu: numer, ciężar, powtórzenia; po prawej przełącznik "zrobione" (accessoryView). */
@interface SLSetCell : UITableViewCell
@property (nonatomic, strong) UILabel *numLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *repsLabel;
@property (nonatomic, strong) UILabel *recordLabel;
@property (nonatomic, strong) UITextField *kgField;
@property (nonatomic, strong) UITextField *repsField;
@property (nonatomic, strong, readonly) UISwitch *doneSwitch;
- (void)setDone:(BOOL)done;
@end

/* Prosty wykres liniowy (bez libm), w ramce jak komórka listy grupowanej. */
@interface SLChartView : UIView
@property (nonatomic, copy) NSArray *values;     /* NSNumber w jednostce wyświetlania */
@property (nonatomic, copy) NSArray *labels;     /* NSString dla pierwszego i ostatniego punktu */
@end

UIToolbar *SLKeyboardToolbar(id target, SEL doneAction);

/* Zdjęcia ćwiczeń (Resources/ex): frame 0 i 1 = dwie klatki ruchu, -1 = miniatura. nil, gdy ćwiczenie nie ma zdjęć. */
UIImage *SLExercisePhoto(NSString *exerciseId, int frame);
/* Miniatura do listy: zdjęcie albo jednolity zapas, żeby teksty w wierszach były wyrównane. */
UIImage *SLExerciseThumb(NSString *exerciseId);
