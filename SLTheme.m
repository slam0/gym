#import "SLTheme.h"
#import "SLStore.h"
#import "sl_core.h"

static UIColor *RGBA(int r, int g, int b, CGFloat a)
{
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a];
}

UIColor *SLTextColor(void)   { return RGBA(238, 240, 244, 1); }
UIColor *SLSubtleColor(void) { return RGBA(150, 156, 168, 1); }
UIColor *SLAccentColor(void) { return RGBA(255, 138, 0, 1); }
UIColor *SLGreenColor(void)  { return RGBA(88, 200, 70, 1); }

/* Tło: ciemny grafit z delikatnymi poziomymi "szczotkowanymi" liniami. */
UIColor *SLBackgroundColor(void)
{
    static UIColor *c;
    if (!c) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(8, 4), YES, 0.0f);
        [RGBA(34, 36, 40, 1) setFill];
        UIRectFill(CGRectMake(0, 0, 8, 4));
        [RGBA(40, 42, 47, 1) setFill];
        UIRectFill(CGRectMake(0, 1, 8, 1));
        [RGBA(30, 32, 36, 1) setFill];
        UIRectFill(CGRectMake(0, 3, 8, 1));
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        c = [UIColor colorWithPatternImage:img];
    }
    return c;
}

static void SLFillGradient(CGContextRef c, CGRect r, UIColor *top, UIColor *bottom)
{
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    NSArray *cols = [NSArray arrayWithObjects:(__bridge id)top.CGColor, (__bridge id)bottom.CGColor, nil];
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, NULL);
    CGContextSaveGState(c);
    CGContextClipToRect(c, r);
    CGContextDrawLinearGradient(c, g, CGPointMake(0, r.origin.y), CGPointMake(0, r.origin.y + r.size.height), 0);
    CGContextRestoreGState(c);
    CGGradientRelease(g);
    CGColorSpaceRelease(cs);
}

/* Błyszczący pasek: jasna górna połowa (odbicie), ciemna dolna. */
static UIImage *SLBarImage(CGFloat height)
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(4.0f, height), NO, 0.0f);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGFloat half = (CGFloat)((int)(height / 2.0f));
    SLFillGradient(c, CGRectMake(0, 0, 4, half), RGBA(112, 116, 126, 1), RGBA(66, 69, 77, 1));
    SLFillGradient(c, CGRectMake(0, half, 4, height - half), RGBA(40, 42, 48, 1), RGBA(22, 23, 27, 1));
    [RGBA(255, 255, 255, 1) setFill];
    CGContextSetAlpha(c, 0.35f);
    CGContextFillRect(c, CGRectMake(0, 0, 4, 1));
    CGContextSetAlpha(c, 1.0f);
    [RGBA(0, 0, 0, 0.7f) setFill];
    CGContextFillRect(c, CGRectMake(0, height - 1, 4, 1));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1)];
}

static UIImage *SLSelectionImage(void)
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.0f, 49.0f), NO, 0.0f);
    [RGBA(255, 255, 255, 0.16f) setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(2, 3, 16, 43) cornerRadius:6] fill];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(12, 9, 12, 9)];
}

void SLStyleNavigationBar(UINavigationBar *bar)
{
    [bar setBackgroundImage:SLBarImage(44.0f) forBarMetrics:UIBarMetricsDefault];
    bar.tintColor = RGBA(58, 61, 69, 1);
    bar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor whiteColor], UITextAttributeTextColor,
        [UIColor colorWithWhite:0.0f alpha:0.85f], UITextAttributeTextShadowColor,
        [NSValue valueWithUIOffset:UIOffsetMake(0, -1)], UITextAttributeTextShadowOffset,
        [UIFont boldSystemFontOfSize:20.0f], UITextAttributeFont, nil];
}

void SLStyleTabBar(UITabBar *bar)
{
    bar.backgroundImage = SLBarImage(49.0f);
    bar.selectionIndicatorImage = SLSelectionImage();
}

/* ---------- ikony zakładek (maski) ---------- */

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
    } else if (kind == 1) {                /* zegar ze strzałką wstecz = historia */
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

static UIImage *SLTabIconTinted(int kind, UIColor *color)
{
    UIImage *mask = SLTabIcon(kind);
    CGRect r = CGRectMake(0, 0, mask.size.width, mask.size.height);
    UIGraphicsBeginImageContextWithOptions(r.size, NO, 0.0f);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [mask drawInRect:r];
    CGContextSetBlendMode(c, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(c, r);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

void SLStyleTabItem(UITabBarItem *item, int kind)
{
    UIColor *off = RGBA(150, 156, 168, 1);
    UIColor *on = SLAccentColor();
    [item setFinishedSelectedImage:SLTabIconTinted(kind, on) withFinishedUnselectedImage:SLTabIconTinted(kind, off)];
    NSValue *offset = [NSValue valueWithUIOffset:UIOffsetMake(0, -1)];
    UIColor *shadow = [UIColor colorWithWhite:0.0f alpha:0.8f];
    [item setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:off, UITextAttributeTextColor, shadow, UITextAttributeTextShadowColor, offset, UITextAttributeTextShadowOffset, nil] forState:UIControlStateNormal];
    [item setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:on, UITextAttributeTextColor, shadow, UITextAttributeTextShadowColor, offset, UITextAttributeTextShadowOffset, nil] forState:UIControlStateSelected];
}

void SLStyleTable(UITableView *table)
{
    table.backgroundView = nil;
    table.backgroundColor = SLBackgroundColor();
    table.separatorColor = RGBA(18, 19, 22, 1);
}

/* ---------- błyszczące przyciski ("żel") ---------- */

UIImage *SLGelImage(int style)
{
    static UIImage *cache[4];
    if (style < 0 || style > 3) style = 1;
    if (cache[style]) return cache[style];
    int top[3], bot[3], border[3];
    switch (style) {
        case 0:  top[0]=255; top[1]=170; top[2]=60;  bot[0]=230; bot[1]=100; bot[2]=0;   border[0]=140; border[1]=60; border[2]=0;  break;
        case 2:  top[0]=235; top[1]=90;  top[2]=90;  bot[0]=170; bot[1]=20;  bot[2]=30;  border[0]=90;  border[1]=8;  border[2]=14; break;
        case 3:  top[0]=130; top[1]=215; top[2]=100; bot[0]=48;  bot[1]=150; bot[2]=40;  border[0]=20;  border[1]=80; border[2]=18; break;
        default: top[0]=104; top[1]=108; top[2]=118; bot[0]=44;  bot[1]=46;  bot[2]=52;  border[0]=10;  border[1]=11; border[2]=14; break;
    }
    CGFloat w = 24.0f, h = 44.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 0.0f);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect r = CGRectMake(0.5f, 0.5f, w - 1.0f, h - 1.5f);
    UIBezierPath *shape = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:9.0f];
    CGContextSaveGState(c);
    [shape addClip];
    SLFillGradient(c, CGRectMake(0, 0, w, h), RGBA(top[0], top[1], top[2], 1), RGBA(bot[0], bot[1], bot[2], 1));
    /* odbicie: szklany połysk na górnej połowie */
    SLFillGradient(c, CGRectMake(0, 0, w, h * 0.5f), RGBA(255, 255, 255, 0.55f), RGBA(255, 255, 255, 0.10f));
    CGContextRestoreGState(c);
    [RGBA(border[0], border[1], border[2], 1) setStroke];
    shape.lineWidth = 1.0f;
    [shape stroke];
    /* lekki cień pod spodem */
    [RGBA(255, 255, 255, 0.18f) setFill];
    CGContextFillRect(c, CGRectMake(6, h - 1, w - 12, 1));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cache[style] = [img resizableImageWithCapInsets:UIEdgeInsetsMake(14, 10, 14, 10)];
    return cache[style];
}

UIButton *SLGelButton(NSString *title, int style, CGRect frame)
{
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = frame;
    [b setBackgroundImage:SLGelImage(style) forState:UIControlStateNormal];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [b setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.6f] forState:UIControlStateNormal];
    b.titleLabel.shadowOffset = CGSizeMake(0, -1);
    b.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    b.adjustsImageWhenHighlighted = YES;
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
        s = [s stringByReplacingOccurrencesOfString:@"." withString:@","];
    }
    return s;
}

double SLParseNumber(NSString *s)
{
    NSString *t = [[s stringByReplacingOccurrencesOfString:@"," withString:@"."]
                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [t doubleValue];
}

NSString *SLUnitName(void) { return [SLStore shared].units == 1 ? @"lb" : @"kg"; }

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
    if (h > 0) return [NSString stringWithFormat:@"%ld godz. %ld min", h, m];
    return [NSString stringWithFormat:@"%ld min", m];
}

NSString *SLGroupedNumber(double v)
{
    long n = (long)(v + 0.5);
    BOOL neg = n < 0;
    if (neg) n = -n;
    NSString *digits = [NSString stringWithFormat:@"%ld", n];
    NSMutableString *out = [NSMutableString string];
    NSUInteger len = [digits length];
    for (NSUInteger i = 0; i < len; i++) {
        if (i > 0 && (len - i) % 3 == 0) [out appendString:@"\u00a0"];
        [out appendString:[digits substringWithRange:NSMakeRange(i, 1)]];
    }
    return neg ? [@"-" stringByAppendingString:out] : out;
}

NSString *SLBigWeightString(double kg)
{
    double v = [SLStore shared].units == 1 ? sl_kg_to_lb(kg) : kg;
    return [NSString stringWithFormat:@"%@ %@", SLGroupedNumber(v), SLUnitName()];
}

static NSDateFormatter *SLFormatter(NSString *fmt)
{
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"pl_PL"];
    f.dateFormat = fmt;
    return f;
}

NSString *SLDateString(double ts)
{
    static NSDateFormatter *f;
    if (!f) f = SLFormatter(@"EEE d MMM yyyy");
    return [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

NSString *SLDateTimeString(double ts)
{
    static NSDateFormatter *f;
    if (!f) f = SLFormatter(@"EEE d MMM, HH:mm");
    return [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

NSString *SLPlural(long n, NSString *one, NSString *few, NSString *many)
{
    switch (sl_plural_pl(n)) {
        case 0: return one;
        case 1: return few;
        default: return many;
    }
}

NSString *SLCountString(long n, NSString *one, NSString *few, NSString *many)
{
    return [NSString stringWithFormat:@"%ld %@", n, SLPlural(n, one, few, many)];
}
