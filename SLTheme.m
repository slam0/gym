#import "SLTheme.h"
#import "SLStore.h"
#import "SLLang.h"
#import "sl_core.h"

/* ---------- motywy: kolor pasków i akcentu ---------- */

#define NTHEMES 6

/* hasTint = 0: pasek zostaje całkiem standardowy (domyślny niebieski iOS 6); swatch tylko do próbki w ustawieniach */
static const struct { NSString *name; int hasTint; int tint[3]; int accent[3]; } kThemes[NTHEMES] = {
    { @"Błękit",   0, {  88, 119, 171 }, {   0,  96, 200 } },
    { @"Grafit",   1, {  62,  65,  72 }, {  72,  78,  92 } },
    { @"Czerwień", 1, { 176,  38,  38 }, { 190,  30,  30 } },
    { @"Zieleń",   1, {  52, 124,  56 }, {  38, 130,  50 } },
    { @"Fiolet",   1, { 100,  64, 156 }, { 110,  60, 190 } },
    { @"Srebro",   1, { 128, 138, 154 }, {  70,  90, 125 } },
};

static NSInteger gTheme = -1;

NSInteger SLThemeCount(void) { return NTHEMES; }

NSInteger SLCurrentTheme(void)
{
    if (gTheme < 0) {
        NSInteger t = [SLStore shared].themeIndex;
        gTheme = (t >= 0 && t < NTHEMES) ? t : 0;
    }
    return gTheme;
}

void SLSetTheme(NSInteger index)
{
    if (index < 0 || index >= NTHEMES) index = 0;
    [SLStore shared].themeIndex = index;
    gTheme = -1;
    SLCurrentTheme();
    [[NSNotificationCenter defaultCenter] postNotificationName:SLAppearanceDidChangeNotification object:nil];
}

NSString *SLThemeName(NSInteger index)
{
    if (index < 0 || index >= NTHEMES) return @"";
    return GL(kThemes[index].name);
}

static UIColor *RGB(const int *c)
{
    return [UIColor colorWithRed:c[0] / 255.0f green:c[1] / 255.0f blue:c[2] / 255.0f alpha:1.0f];
}

/* kolor paska bieżącego motywu; nil = domyślny pasek systemu */
static UIColor *BarTint(void)
{
    NSInteger t = SLCurrentTheme();
    return kThemes[t].hasTint ? RGB(kThemes[t].tint) : nil;
}

UIColor *SLBackgroundColor(void) { return [UIColor groupTableViewBackgroundColor]; }
UIColor *SLSubtleColor(void)     { return [UIColor colorWithRed:0.298f green:0.337f blue:0.424f alpha:1.0f]; }
UIColor *SLAccentColor(void)     { return RGB(kThemes[SLCurrentTheme()].accent); }
UIColor *SLDangerColor(void)     { return [UIColor colorWithRed:0.75f green:0.05f blue:0.05f alpha:1.0f]; }

void SLStyleShadow(UILabel *l)
{
    l.shadowColor = [UIColor whiteColor];
    l.shadowOffset = CGSizeMake(0, 1);
}

/* ---------- paski: standardowe, tylko z kolorem motywu ---------- */

void SLStyleNavigationBar(UINavigationBar *bar) { bar.tintColor = BarTint(); }
void SLStyleTabBar(UITabBar *bar)               { bar.tintColor = BarTint(); }
void SLStyleToolbar(UIToolbar *bar)             { bar.tintColor = BarTint(); }
void SLStyleSearchBar(UISearchBar *bar)         { bar.tintColor = BarTint(); }

void SLStyleSegmented(UISegmentedControl *sc)  { if (BarTint()) sc.tintColor = BarTint(); }

void SLStyleTable(UITableView *table)
{
    table.backgroundView = nil;
    table.backgroundColor = SLBackgroundColor();
}

/* ---------- ikony zakładek (maski; kolor i połysk nakłada system) ---------- */

UIImage *SLTabIcon(int kind)
{
    CGFloat s = 30.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s, s), NO, 0.0f);
    [[UIColor blackColor] setFill];
    [[UIColor blackColor] setStroke];
    if (kind == 0) {                       /* sztanga */
        [[UIBezierPath bezierPathWithRect:CGRectMake(7, 13.5f, 16, 3)] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(3, 8, 5, 14) cornerRadius:1.5f] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(22, 8, 5, 14) cornerRadius:1.5f] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0.5f, 12, 2.5f, 6)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(27, 12, 2.5f, 6)] fill];
    } else if (kind == 1) {                /* zegar = historia */
        UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(4, 4, 22, 22)];
        ring.lineWidth = 3.0f;
        [ring stroke];
        UIBezierPath *h = [UIBezierPath bezierPath];
        [h moveToPoint:CGPointMake(15, 8.5f)];
        [h addLineToPoint:CGPointMake(15, 15.5f)];
        [h addLineToPoint:CGPointMake(20.5f, 18.5f)];
        h.lineWidth = 2.6f;
        h.lineCapStyle = kCGLineCapRound;
        h.lineJoinStyle = kCGLineJoinRound;
        [h stroke];
    } else if (kind == 2) {                /* lista */
        for (int i = 0; i < 3; i++) {
            CGFloat y = 6.5f + i * 7.5f;
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(3, y, 4, 4)] fill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(10, y + 0.5f, 17, 3)  cornerRadius:1.5f] fill];
        }
    } else if (kind == 4) {                /* dom = główna */
        UIBezierPath *roof = [UIBezierPath bezierPath];
        [roof moveToPoint:CGPointMake(15, 3.5f)];
        [roof addLineToPoint:CGPointMake(28, 15.5f)];
        [roof addLineToPoint:CGPointMake(23.5f, 15.5f)];
        [roof addLineToPoint:CGPointMake(23.5f, 26)];
        [roof addLineToPoint:CGPointMake(17.5f, 26)];
        [roof addLineToPoint:CGPointMake(17.5f, 18.5f)];
        [roof addLineToPoint:CGPointMake(12.5f, 18.5f)];
        [roof addLineToPoint:CGPointMake(12.5f, 26)];
        [roof addLineToPoint:CGPointMake(6.5f, 26)];
        [roof addLineToPoint:CGPointMake(6.5f, 15.5f)];
        [roof addLineToPoint:CGPointMake(2, 15.5f)];
        [roof closePath];
        [roof fill];
    } else {                               /* suwaki = ustawienia */
        static const CGFloat knob[3] = { 19, 9, 16 };
        for (int i = 0; i < 3; i++) {
            CGFloat y = 7.0f + i * 8.0f;
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(3, y + 1.5f, 24, 2.5f) cornerRadius:1.2f] fill];
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(knob[i] - 3.5f, y - 0.5f, 7, 7)] fill];
        }
    }
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

/* próbka koloru motywu na liście wyboru: płaski, zaokrąglony kwadrat */
UIImage *SLThemeSwatch(NSInteger index)
{
    if (index < 0 || index >= NTHEMES) index = 0;
    CGFloat s = 29.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s, s), NO, 0.0f);
    UIBezierPath *shape = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(1.5f, 1.5f, s - 3.0f, s - 3.0f) cornerRadius:6.0f];
    [RGB(kThemes[index].tint) setFill];
    [shape fill];
    [[UIColor colorWithWhite:0.0f alpha:0.35f] setStroke];
    shape.lineWidth = 1.0f;
    [shape stroke];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

/* ---------- przyciski systemowe ---------- */

UIButton *SLButton(NSString *title, int style, CGRect frame)
{
    UIButton *b = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    b.frame = frame;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.titleLabel.minimumScaleFactor = 0.65f;
    if (style == 2) [b setTitleColor:SLDangerColor() forState:UIControlStateNormal];
    return b;
}

UIBarButtonItem *SLBarButton(NSString *title, id target, SEL action)
{
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:target action:action];
}

/* ---------- formatowanie ---------- */

NSString *SLNumberString(double v)
{
    double r = sl_round2(v);
    NSString *s;
    if (r == (double)(long)r) s = [NSString stringWithFormat:@"%ld", (long)r];
    else {
        s = [NSString stringWithFormat:@"%.2f", r];
        while ([s hasSuffix:@"0"]) s = [s substringToIndex:[s length] - 1];
        if (SLLanguage() != 1) s = [s stringByReplacingOccurrencesOfString:@"." withString:@","];
    }
    return s;
}

double SLParseNumber(NSString *s)
{
    NSString *t = [[s stringByReplacingOccurrencesOfString:@"," withString:@"."]
                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [t doubleValue];
}

NSString *SLUnitName(void) { return GL([SLStore shared].units == 1 ? @"lb" : @"kg"); }

NSString *SLWeightNumber(double kg)
{
    double v = [SLStore shared].units == 1 ? sl_kg_to_lb(kg) : kg;
    return SLNumberString(v);
}

NSString *SLWeightString(double kg)
{
    return [NSString stringWithFormat:@"%@ %@", SLWeightNumber(kg), SLUnitName()];
}

double SLKgFromDisplay(double v)
{
    return [SLStore shared].units == 1 ? sl_lb_to_kg(v) : v;
}

NSString *SLDurationString(long seconds)
{
    long h, m, s;
    sl_split_seconds(seconds, &h, &m, &s);
    if (h > 0) return [NSString stringWithFormat:@"%ld:%02ld:%02ld", h, m, s];
    return [NSString stringWithFormat:@"%02ld:%02ld", m, s];
}

NSString *SLLongDuration(double seconds)
{
    long total = (long)(seconds + 30.0) / 60;      /* zaokrąglenie do minut */
    long h = total / 60, m = total % 60;
    if (h > 0) return [NSString stringWithFormat:@"%ld %@ %ld %@", h, GL(@"godz."), m, GL(@"min")];
    return [NSString stringWithFormat:@"%ld %@", m, GL(@"min")];
}

NSString *SLGroupedNumber(double v)
{
    long n = (long)(v + 0.5);
    BOOL neg = n < 0;
    if (neg) n = -n;
    NSString *digits = [NSString stringWithFormat:@"%ld", n];
    NSString *sep = SLLanguage() == 1 ? @"," : @" ";
    NSMutableString *out = [NSMutableString string];
    NSUInteger len = [digits length];
    for (NSUInteger i = 0; i < len; i++) {
        if (i > 0 && (len - i) % 3 == 0) [out appendString:sep];
        [out appendString:[digits substringWithRange:NSMakeRange(i, 1)]];
    }
    return neg ? [@"-" stringByAppendingString:out] : out;
}

NSString *SLBigWeightString(double kg)
{
    double v = [SLStore shared].units == 1 ? sl_kg_to_lb(kg) : kg;
    return [NSString stringWithFormat:@"%@ %@", SLGroupedNumber(v), SLUnitName()];
}

/* formatery trzymamy osobno dla każdego języka */
static NSString *SLFormatted(double ts, int kind)
{
    static NSDateFormatter *cache[3][3];
    NSInteger l = SLLanguage();
    if (!cache[l][kind]) {
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.locale = SLLocale();
        f.dateFormat = kind == 0 ? @"EEE d MMM yyyy" : (kind == 1 ? @"EEE d MMM, HH:mm" : @"d MMM");
        cache[l][kind] = f;
    }
    return [cache[l][kind] stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

NSString *SLDateString(double ts)      { return SLFormatted(ts, 0); }
NSString *SLDateTimeString(double ts)  { return SLFormatted(ts, 1); }
NSString *SLShortDateString(double ts) { return SLFormatted(ts, 2); }
