#import <Foundation/Foundation.h>

/* Języki: polski (podstawowy), angielski, rosyjski.
   W kodzie wszystkie napisy są po polsku, a GL() podmienia je na wybrany język. */

extern NSString *const SLAppearanceDidChangeNotification;   /* zmiana języka albo motywu */

/* Język faktycznie używany: 0 polski, 1 angielski, 2 rosyjski. */
NSInteger SLLanguage(void);
/* Ustawienie zapisane w pliku: 0 automatycznie (wg telefonu), 1 polski, 2 English, 3 Русский. */
NSInteger SLLanguageSetting(void);
void SLSetLanguageSetting(NSInteger setting);
NSString *SLLanguageSettingName(NSInteger setting);          /* nazwa w jej własnym języku */
NSLocale *SLLocale(void);

/* Tłumaczy polski napis; gdy brak tłumaczenia, zwraca go bez zmian. */
NSString *GL(NSString *pl);

/* Rzeczowniki z odmianą liczebnikową. */
enum { SLNounSet = 0, SLNounExercise = 1, SLNounRep = 2, SLNounWorkout = 3 };
NSString *SLNounString(long n, int noun);                    /* "serii" */
NSString *SLCountString(long n, int noun);                   /* "5 serii" */
