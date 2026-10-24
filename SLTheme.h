#import <UIKit/UIKit.h>

/* Wygląd "grafit z połyskiem" w stylu iOS 6 oraz drobne funkcje pomocnicze. */

UIColor *SLBackgroundColor(void);       /* teksturowane tło tabel */
UIColor *SLTextColor(void);
UIColor *SLSubtleColor(void);
UIColor *SLAccentColor(void);           /* pomarańcz */
UIColor *SLGreenColor(void);

void SLStyleNavigationBar(UINavigationBar *bar);
void SLStyleTabBar(UITabBar *bar);
void SLStyleTabItem(UITabBarItem *item, int kind);   /* 0 trening, 1 historia, 2 ćwiczenia, 3 ustawienia, 4 główna */
UIImage *SLTabIcon(int kind);
void SLStyleTable(UITableView *table);

/* styl: 0 pomarańczowy, 1 grafitowy, 2 czerwony, 3 zielony */
UIImage *SLGelImage(int style);
UIButton *SLGelButton(NSString *title, int style, CGRect frame);
UIBarButtonItem *SLBarButton(NSString *title, id target, SEL action);

/* formatowanie */
NSString *SLNumberString(double v);                 /* 62,5 (bez zbędnych zer, przecinek) */
double SLParseNumber(NSString *s);                  /* akceptuje przecinek i kropkę */
NSString *SLWeightNumber(double kg);                /* liczba w jednostce wybranej w ustawieniach */
NSString *SLWeightString(double kg);                /* "62,5 kg" */
double SLKgFromDisplay(double v);
NSString *SLUnitName(void);
NSString *SLDurationString(long seconds);          /* 12:05 albo 1:02:05 */
NSString *SLLongDuration(double seconds);          /* 12 godz. 34 min */
NSString *SLGroupedNumber(double v);               /* 128 450 (spacja co trzy cyfry) */
NSString *SLBigWeightString(double kg);            /* 128 450 kg */
NSString *SLDateString(double ts);                 /* "pon. 21 paź" */
NSString *SLDateTimeString(double ts);
NSString *SLPlural(long n, NSString *one, NSString *few, NSString *many);
NSString *SLCountString(long n, NSString *one, NSString *few, NSString *many);   /* "5 serii" */
