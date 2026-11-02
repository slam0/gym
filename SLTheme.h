#import <UIKit/UIKit.h>

/* Wygląd: standardowy UIKit z iOS 6 (paski, listy grupowane, kontrolki systemowe).
   Motyw to tylko kolor pasków (tintColor) oraz kolor akcentu w tekstach i na wykresie.
   Poniżej też drobne funkcje pomocnicze do formatowania liczb, dat i jednostek. */

/* ---- motywy ---- */
NSInteger SLThemeCount(void);
NSInteger SLCurrentTheme(void);
void SLSetTheme(NSInteger index);               /* zapisuje i ogłasza SLAppearanceDidChangeNotification */
NSString *SLThemeName(NSInteger index);         /* przetłumaczona nazwa */
UIImage *SLThemeSwatch(NSInteger index);        /* mała próbka koloru paska */

UIColor *SLBackgroundColor(void);       /* systemowe tło list grupowanych (groupTableViewBackgroundColor) */
UIColor *SLSubtleColor(void);           /* szary tekst na tle list grupowanych (jak nagłówki w Ustawieniach) */
UIColor *SLAccentColor(void);           /* kolor akcentu bieżącego motywu */
UIColor *SLDangerColor(void);
void SLStyleShadow(UILabel *label);     /* biały cień pod tekstem na tle list grupowanych */

void SLStyleNavigationBar(UINavigationBar *bar);   /* tylko tintColor motywu; reszta to standard iOS */
void SLStyleTabBar(UITabBar *bar);
void SLStyleToolbar(UIToolbar *bar);
void SLStyleSearchBar(UISearchBar *bar);
void SLStyleSegmented(UISegmentedControl *sc);     /* kolor motywu na stałej kontrolce segmentowej */
void SLStyleTable(UITableView *table);             /* lista grupowana: systemowe tło */
UIImage *SLTabIcon(int kind);           /* maska dla UITabBarItem: 0 trening, 1 historia, 2 ćwiczenia, 3 ustawienia, 4 główna */

/* styl: 0 zwykły, 2 czerwony (usuń) */
UIButton *SLButton(NSString *title, int style, CGRect frame);   /* standardowy przycisk UIButtonTypeRoundedRect */
UIBarButtonItem *SLBarButton(NSString *title, id target, SEL action);

/* formatowanie */
NSString *SLNumberString(double v);                 /* 62,5 albo 62.5 (bez zbędnych zer) */
double SLParseNumber(NSString *s);                  /* akceptuje przecinek i kropkę */
NSString *SLWeightNumber(double kg);                /* liczba w jednostce wybranej w ustawieniach */
NSString *SLWeightString(double kg);                /* "62,5 kg" */
double SLKgFromDisplay(double v);
NSString *SLUnitName(void);
NSString *SLDurationString(long seconds);          /* 12:05 albo 1:02:05 */
NSString *SLLongDuration(double seconds);          /* 12 godz. 34 min */
NSString *SLGroupedNumber(double v);               /* 128 450 */
NSString *SLBigWeightString(double kg);            /* 128 450 kg */
NSString *SLDateString(double ts);                 /* "pon. 21 paź 2024" */
NSString *SLDateTimeString(double ts);
NSString *SLShortDateString(double ts);            /* "21 paź" */
