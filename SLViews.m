#import "SLViews.h"
#import "SLTheme.h"
#import "SLLang.h"

/* ---------- komórka ---------- */

@implementation SLCell

+ (SLCell *)cellForTable:(UITableView *)table identifier:(NSString *)ident
{
    SLCell *cell = [table dequeueReusableCellWithIdentifier:ident];
    if (!cell) cell = [[SLCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
    return cell;
}

@end

/* ---------- nagłówek sekcji ---------- */

@implementation SLSectionHeader

- (UILabel *)makeLabel:(CGRect)f bold:(BOOL)bold
{
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = SLSubtleColor();
    l.font = bold ? [UIFont boldSystemFontOfSize:17.0f] : [UIFont systemFontOfSize:15.0f];
    SLStyleShadow(l);
    [self addSubview:l];
    return l;
}

- (id)initWithTitle:(NSString *)title right:(NSString *)right
{
    if ((self = [super initWithFrame:CGRectMake(0, 0, 320, 34)])) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        BOOL hasRight = [right length] > 0;
        _titleLabel = [self makeLabel:CGRectMake(20, 8, hasRight ? 150 : 280, 22) bold:YES];
        _titleLabel.text = title;
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _rightLabel = [self makeLabel:CGRectMake(172, 8, 128, 22) bold:NO];
        _rightLabel.textAlignment = NSTextAlignmentRight;
        _rightLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _rightLabel.adjustsFontSizeToFitWidth = YES;
        _rightLabel.minimumScaleFactor = 0.7f;
        _rightLabel.text = right;
    }
    return self;
}

@end

UIView *SLHeaderForTitle(NSString *title, NSString *right)
{
    return [[SLSectionHeader alloc] initWithTitle:title right:right];
}

UIView *SLFooterForText(NSString *text)
{
    CGFloat h = SLFooterHeight(text);
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, h)];
    v.backgroundColor = [UIColor clearColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 6, 280, h - 6)];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = SLSubtleColor();
    l.font = [UIFont systemFontOfSize:14.0f];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 0;
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    SLStyleShadow(l);
    l.text = text;
    [v addSubview:l];
    return v;
}

CGFloat SLFooterHeight(NSString *text)
{
    if (![text length]) return 12.0f;
    CGSize sz = [text sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(280, 400) lineBreakMode:NSLineBreakByWordWrapping];
    return sz.height + 16.0f;
}

/* ---------- klawiatura ---------- */

UIToolbar *SLKeyboardToolbar(id target, SEL doneAction)
{
    UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    tb.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:doneAction];
    tb.items = [NSArray arrayWithObjects:flex, done, nil];
    return tb;
}

/* ---------- komórka serii ---------- */

@implementation SLSetCell

- (UITextField *)makeField:(CGRect)frame
{
    UITextField *f = [[UITextField alloc] initWithFrame:frame];
    f.borderStyle = UITextBorderStyleRoundedRect;
    f.font = [UIFont systemFontOfSize:17.0f];
    f.textAlignment = NSTextAlignmentCenter;
    f.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    f.clearButtonMode = UITextFieldViewModeNever;
    f.autocorrectionType = UITextAutocorrectionTypeNo;
    return f;
}

- (UILabel *)makeLabel:(CGRect)frame size:(CGFloat)size bold:(BOOL)bold color:(UIColor *)color align:(NSTextAlignment)a
{
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = color;
    l.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    l.textAlignment = a;
    [self.contentView addSubview:l];
    return l;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuse
{
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuse])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIColor *gray = [UIColor grayColor];
        /* szerokość contentView po odjęciu przełącznika to ok. 210 pt */
        self.numLabel = [self makeLabel:CGRectMake(2, 12, 20, 22) size:16 bold:YES color:gray align:NSTextAlignmentCenter];
        self.kgField = [self makeField:CGRectMake(24, 6, 64, 31)];
        self.kgField.keyboardType = UIKeyboardTypeDecimalPad;
        [self.contentView addSubview:self.kgField];
        self.unitLabel = [self makeLabel:CGRectMake(90, 12, 22, 22) size:13 bold:NO color:gray align:NSTextAlignmentLeft];
        self.repsField = [self makeField:CGRectMake(114, 6, 46, 31)];
        self.repsField.keyboardType = UIKeyboardTypeNumberPad;
        [self.contentView addSubview:self.repsField];
        self.repsLabel = [self makeLabel:CGRectMake(162, 12, 46, 22) size:12 bold:NO color:gray align:NSTextAlignmentLeft];
        self.repsLabel.text = GL(@"powt.");
        self.recordLabel = [self makeLabel:CGRectMake(24, 39, 190, 12) size:10 bold:YES color:SLAccentColor() align:NSTextAlignmentLeft];
        _doneSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.accessoryView = _doneSwitch;
    }
    return self;
}

- (void)setDone:(BOOL)done
{
    [self.doneSwitch setOn:done animated:NO];
    self.kgField.alpha = self.repsField.alpha = done ? 0.6f : 1.0f;
}

@end

/* ---------- wykres ---------- */

@implementation SLChartView

- (id)initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f])) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    /* panel wygląda jak komórka listy grupowanej: biały, zaokrąglony, z szarą ramką */
    UIBezierPath *panel = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 0.5f, 0.5f) cornerRadius:10];
    [[UIColor whiteColor] setFill];
    [panel fill];
    [[UIColor colorWithWhite:0.68f alpha:1.0f] setStroke];
    [panel stroke];

    NSArray *vals = self.values;
    CGFloat left = 40, right = 14, top = 14, bottom = 28;
    CGRect plot = CGRectMake(left, top, b.size.width - left - right, b.size.height - top - bottom);
    UIColor *gray = [UIColor grayColor];
    if ([vals count] == 0) {
        [gray set];
        [GL(@"Brak danych") drawInRect:CGRectMake(0, b.size.height / 2 - 9, b.size.width, 18) withFont:[UIFont systemFontOfSize:14] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentCenter];
        return;
    }
    double mn = [[vals objectAtIndex:0] doubleValue], mx = mn;
    for (NSNumber *n in vals) { double v = [n doubleValue]; if (v < mn) mn = v; if (v > mx) mx = v; }
    if (mx - mn < 0.0001) { mx += 1; mn -= 1; if (mn < 0) mn = 0; }
    double pad = (mx - mn) * 0.12;
    double lo = mn - pad, hi = mx + pad;
    if (lo < 0) lo = 0;

    /* linie siatki i opisy osi Y */
    UIFont *small = [UIFont systemFontOfSize:10];
    for (int i = 0; i < 4; i++) {
        CGFloat y = plot.origin.y + plot.size.height * i / 3.0f;
        [[UIColor colorWithWhite:0.0f alpha:0.12f] setFill];
        CGContextFillRect(c, CGRectMake(plot.origin.x, (CGFloat)((int)y), plot.size.width, 1));
        double v = hi - (hi - lo) * i / 3.0;
        [gray set];
        [SLNumberString(v) drawInRect:CGRectMake(2, y - 6, left - 6, 12) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
    }
    NSUInteger n = [vals count];
    UIBezierPath *line = [UIBezierPath bezierPath];
    NSMutableArray *pts = [NSMutableArray array];
    for (NSUInteger i = 0; i < n; i++) {
        CGFloat x = (n == 1) ? plot.origin.x + plot.size.width / 2 : plot.origin.x + plot.size.width * i / (CGFloat)(n - 1);
        double v = [[vals objectAtIndex:i] doubleValue];
        CGFloat y = plot.origin.y + plot.size.height * (CGFloat)((hi - v) / (hi - lo));
        CGPoint p = CGPointMake(x, y);
        [pts addObject:[NSValue valueWithCGPoint:p]];
        if (i == 0) [line moveToPoint:p]; else [line addLineToPoint:p];
    }
    if (n > 1) {
        UIBezierPath *area = [UIBezierPath bezierPathWithCGPath:line.CGPath];
        CGPoint last = [[pts lastObject] CGPointValue], first = [[pts objectAtIndex:0] CGPointValue];
        [area addLineToPoint:CGPointMake(last.x, plot.origin.y + plot.size.height)];
        [area addLineToPoint:CGPointMake(first.x, plot.origin.y + plot.size.height)];
        [area closePath];
        [[SLAccentColor() colorWithAlphaComponent:0.16f] setFill];
        [area fill];
    }
    line.lineWidth = 2.5f;
    line.lineJoinStyle = kCGLineJoinRound;
    [SLAccentColor() setStroke];
    [line stroke];
    for (NSValue *pv in pts) {
        CGPoint p = [pv CGPointValue];
        [[UIColor whiteColor] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - 3.5f, p.y - 3.5f, 7, 7)] fill];
        [SLAccentColor() setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - 2.0f, p.y - 2.0f, 4, 4)] fill];
    }
    /* opisy osi X */
    [gray set];
    NSArray *lb = self.labels;
    if ([lb count] >= 1) [[lb objectAtIndex:0] drawInRect:CGRectMake(plot.origin.x - 20, b.size.height - 20, 110, 14) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentLeft];
    if ([lb count] >= 2) [[lb objectAtIndex:1] drawInRect:CGRectMake(b.size.width - right - 110, b.size.height - 20, 110 + 8, 14) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
}

@end


/* ---------- zdjęcia ćwiczeń ---------- */

UIImage *SLExercisePhoto(NSString *exerciseId, int frame)
{
    static NSCache *cache = nil;
    if (![exerciseId length]) return nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:160]; }
    NSString *key = [exerciseId stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    NSString *name = frame < 0 ? [key stringByAppendingString:@"_t"] : [NSString stringWithFormat:@"%@_%d", key, frame];
    id hit = [cache objectForKey:name];
    if (hit) return [hit isKindOfClass:[UIImage class]] ? hit : nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg" inDirectory:@"ex"];
    UIImage *img = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (img && frame < 0 && [img respondsToSelector:@selector(CGImage)])
        img = [UIImage imageWithCGImage:img.CGImage scale:2.0f orientation:UIImageOrientationUp];     /* 120x80 px = 60x40 pt */
    [cache setObject:(img ? (id)img : (id)[NSNull null]) forKey:name];
    return img;
}

UIImage *SLExerciseThumb(NSString *exerciseId)
{
    static UIImage *blank = nil;
    UIImage *img = SLExercisePhoto(exerciseId, -1);
    if (img) return img;
    if (!blank) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 40), NO, 0);
        CGContextRef c = UIGraphicsGetCurrentContext();
        [[UIColor colorWithWhite:0.5f alpha:0.18f] setFill];
        CGContextFillRect(c, CGRectMake(0, 0, 60, 40));
        blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return blank;
}
