#import <UIKit/UIKit.h>

/* Wygląd w stylu iOS 6 ("grafit z połyskiem") z kilkoma motywami kolorystycznymi
   oraz drobne funkcje pomocnicze do formatowania liczb, dat i jednostek. */

/* ---- paleta bieżącego motywu ---- */
typedef struct {
    int accent[3], accentGelT[3], accentGelB[3], accentGelBorder[3];
    int bg[3], bgHi[3], bgLo[3];
    int barT1[3], barT2[3], barB1[3], barB2[3], barTint[3];
    int cellT1[3], cellT2[3], cellB1[3], cellB2[3];
    int selT1[3], selT2[3], selB1[3], selB2[3];
    int text[3], subtle[3], tabOff[3], tabOn[3];
    int hdrT[3], hdrB[3], hdrTitle[3], hdrRight[3];
    int fieldT[3], fieldB[3], fieldText[3];
    int tileT[3], tileB[3], tileText[3];
    int panelT[3], panelB[3], grid[3];
    int sep[3], neutT[3], neutB[3], neutBorder[3];
    int shadow[3], chrome[3], danger[3];
    float gridAlpha, shadowAlpha, shadowDY, cellHiAlpha, cellLoAlpha;
    int light;
} SLPalette;

const SLPalette *SLP(void);
UIColor *SLRGB(const int *rgb, CGFloat alpha);

/* ---- motywy ---- */
NSInteger SLThemeCount(void);
NSInteger SLCurrentTheme(void);
void SLSetTheme(NSInteger index);               /* zapisuje i ogłasza SLAppearanceDidChangeNotification */
NSString *SLThemeName(NSInteger index);         /* przetłumaczona nazwa */
UIImage *SLThemeSwatch(NSInteger index);        /* mała błyszcząca próbka koloru */

UIColor *SLBackgroundColor(void);       /* teksturowane tło tabel */
UIColor *SLTextColor(void);
UIColor *SLSubtleColor(void);
UIColor *SLAccentColor(void);
UIColor *SLGreenColor(void);
void SLStyleShadow(UILabel *label);     /* cień tekstu pasujący do motywu */

void SLStyleNavigationBar(UINavigationBar *bar);
void SLStyleTabBar(UITabBar *bar);
void SLStyleTabItem(UITabBarItem *item, int kind);   /* 0 trening, 1 historia, 2 ćwiczenia, 3 ustawienia, 4 główna */
void SLStyleSearchBar(UISearchBar *bar);
UIImage *SLTabIcon(int kind);
void SLStyleTable(UITableView *table);

/* styl: 0 kolor motywu, 1 neutralny, 2 czerwony, 3 zielony */
UIImage *SLGelImage(int style);
UIButton *SLGelButton(NSString *title, int style, CGRect frame);
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
