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

/* Wykres słupkowy (np. treningi w tygodniach). */
@interface SLBarChartView : UIView
@property (nonatomic, copy) NSArray *values;     /* NSNumber, od najstarszego */
@property (nonatomic, copy) NSArray *labels;     /* opis pod każdym słupkiem (może być krótszy / nil) */
@property (nonatomic, copy) NSString *unit;      /* np. "kg" przy opisie wartości, może być nil */
@end

/* Siatka miesiąca z zaznaczonymi dniami treningu. */
@interface SLCalendarView : UIView
@property (nonatomic) NSInteger year, month;            /* miesiąc do pokazania */
@property (nonatomic, copy) NSSet *markedDays;          /* NSNumber: dzień miesiąca (1-31) */
@property (nonatomic) NSInteger selectedDay;            /* 0 = brak */
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;                       /* wywoływane po dotknięciu dnia; selectedDay ustawione */
@end

/* Błyszczący kafelek z dużą liczbą i podpisem */
@interface SLStatView : UIView
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *caption;
@end

UIToolbar *SLKeyboardToolbar(id target, SEL doneAction);
UIImage *SLCheckImage(BOOL on);

/* Zdjęcia ćwiczeń (Resources/ex): frame 0 i 1 = dwie klatki ruchu, -1 = miniatura. nil, gdy ćwiczenie nie ma zdjęć. */
UIImage *SLExercisePhoto(NSString *exerciseId, int frame);
NSUInteger SLExercisePhotoCount(void);     /* liczba zdjęć w aplikacji (0 = brak pliku ex.pack) */
/* Miniatura do listy: zdjęcie albo jednolity zapas, żeby teksty w wierszach były wyrównane. */
UIImage *SLExerciseThumb(NSString *exerciseId);
