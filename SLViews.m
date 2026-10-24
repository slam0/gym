#import "SLViews.h"
#import "SLTheme.h"

static UIColor *C(int r, int g, int b, CGFloat a)
{
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a];
}

static void Gradient(CGContextRef c, CGRect r, UIColor *top, UIColor *bottom)
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

/* ---------- tło komórki ---------- */

@interface SLGlossBackground : UIView
@property (nonatomic) BOOL selected;
@end

@implementation SLGlossBackground
- (id)initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f])) {
        self.opaque = YES;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    CGFloat half = (CGFloat)((int)(b.size.height / 2.0f));
    if (_selected) {
        Gradient(c, CGRectMake(0, 0, b.size.width, half), C(150, 84, 20, 1), C(112, 60, 12, 1));
        Gradient(c, CGRectMake(0, half, b.size.width, b.size.height - half), C(92, 48, 8, 1), C(72, 36, 4, 1));
    } else {
        Gradient(c, CGRectMake(0, 0, b.size.width, half), C(66, 69, 77, 1), C(52, 55, 62, 1));
        Gradient(c, CGRectMake(0, half, b.size.width, b.size.height - half), C(44, 46, 52, 1), C(38, 40, 45, 1));
    }
    [C(255, 255, 255, 0.14f) setFill];
    CGContextFillRect(c, CGRectMake(0, 0, b.size.width, 1));
    [C(0, 0, 0, 0.55f) setFill];
    CGContextFillRect(c, CGRectMake(0, b.size.height - 1, b.size.width, 1));
}
@end

@implementation SLCell

+ (SLCell *)cellForTable:(UITableView *)table identifier:(NSString *)ident
{
    SLCell *cell = [table dequeueReusableCellWithIdentifier:ident];
    if (!cell) cell = [[SLCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
    return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuse
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuse])) {
        self.backgroundView = [[SLGlossBackground alloc] initWithFrame:self.bounds];
        SLGlossBackground *sel = [[SLGlossBackground alloc] initWithFrame:self.bounds];
        sel.selected = YES;
        self.selectedBackgroundView = sel;
        self.textLabel.textColor = SLTextColor();
        self.textLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
        self.textLabel.shadowOffset = CGSizeMake(0, -1);
        self.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.textColor = SLSubtleColor();
        self.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}
@end

/* ---------- nagłówek sekcji ---------- */

@interface SLSectionHeader ()
{
    NSString *_title, *_right;
}
@end

@implementation SLSectionHeader
- (id)initWithTitle:(NSString *)title right:(NSString *)right
{
    if ((self = [super initWithFrame:CGRectMake(0, 0, 320, 26)])) {
        _title = [title copy];
        _right = [right copy];
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    Gradient(c, b, C(30, 32, 36, 0.97f), C(14, 15, 18, 0.97f));
    [C(255, 255, 255, 0.10f) setFill];
    CGContextFillRect(c, CGRectMake(0, 0, b.size.width, 1));
    [C(0, 0, 0, 0.8f) setFill];
    CGContextFillRect(c, CGRectMake(0, b.size.height - 1, b.size.width, 1));
    UIFont *f = [UIFont boldSystemFontOfSize:13.0f];
    CGContextSetShadowWithColor(c, CGSizeMake(0, -1), 0, C(0, 0, 0, 0.9f).CGColor);
    [SLAccentColor() set];
    [_title drawInRect:CGRectMake(12, 5, b.size.width - 100, 18) withFont:f lineBreakMode:NSLineBreakByTruncatingTail];
    if ([_right length]) {
        [SLSubtleColor() set];
        [_right drawInRect:CGRectMake(b.size.width - 160, 5, 148, 18) withFont:f lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentRight];
    }
}
@end

UIView *SLHeaderForTitle(NSString *title, NSString *right)
{
    return [[SLSectionHeader alloc] initWithTitle:title right:right];
}

/* ---------- klawiatura ---------- */

UIToolbar *SLKeyboardToolbar(id target, SEL doneAction)
{
    UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 38)];
    tb.barStyle = UIBarStyleBlack;
    tb.translucent = YES;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Gotowe" style:UIBarButtonItemStyleDone target:target action:doneAction];
    tb.items = [NSArray arrayWithObjects:flex, done, nil];
    return tb;
}

UIImage *SLCheckImage(BOOL on)
{
    CGFloat s = 26.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s, s), NO, 0.0f);
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(5, 14)];
    [p addLineToPoint:CGPointMake(10.5f, 19.5f)];
    [p addLineToPoint:CGPointMake(21, 7)];
    p.lineWidth = 4.0f;
    p.lineCapStyle = kCGLineCapRound;
    p.lineJoinStyle = kCGLineJoinRound;
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (on) {
        CGContextSetShadowWithColor(c, CGSizeMake(0, -1), 0, C(0, 0, 0, 0.6f).CGColor);
        [[UIColor whiteColor] setStroke];
    } else {
        [C(150, 156, 168, 0.85f) setStroke];
    }
    [p stroke];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

/* ---------- komórka serii ---------- */

static UIImage *SLFieldImage(void)
{
    static UIImage *img;
    if (img) return img;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 34), NO, 0.0f);
    CGContextRef c = UIGraphicsGetCurrentContext();
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, 19, 32) cornerRadius:7];
    CGContextSaveGState(c);
    [p addClip];
    Gradient(c, CGRectMake(0, 0, 20, 34), C(12, 13, 16, 1), C(30, 32, 37, 1));
    CGContextRestoreGState(c);
    [C(0, 0, 0, 0.9f) setStroke];
    [p stroke];
    [C(255, 255, 255, 0.12f) setFill];
    CGContextFillRect(c, CGRectMake(5, 33, 10, 1));
    UIImage *raw = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    img = [raw resizableImageWithCapInsets:UIEdgeInsetsMake(10, 8, 10, 8)];
    return img;
}

@implementation SLSetCell

- (UITextField *)makeField:(CGRect)frame
{
    UITextField *f = [[UITextField alloc] initWithFrame:frame];
    f.background = SLFieldImage();
    f.textColor = [UIColor whiteColor];
    f.font = [UIFont boldSystemFontOfSize:18.0f];
    f.textAlignment = NSTextAlignmentCenter;
    f.borderStyle = UITextBorderStyleNone;
    f.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    f.keyboardAppearance = UIKeyboardAppearanceAlert;
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
    l.shadowColor = [UIColor colorWithWhite:0 alpha:0.8f];
    l.shadowOffset = CGSizeMake(0, -1);
    [self.contentView addSubview:l];
    return l;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuse
{
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuse])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundView = [[SLGlossBackground alloc] initWithFrame:self.bounds];
        self.numLabel = [self makeLabel:CGRectMake(6, 14, 28, 22) size:16 bold:YES color:SLSubtleColor() align:NSTextAlignmentCenter];
        self.kgField = [self makeField:CGRectMake(38, 8, 74, 34)];
        self.kgField.keyboardType = UIKeyboardTypeDecimalPad;
        [self.contentView addSubview:self.kgField];
        self.unitLabel = [self makeLabel:CGRectMake(114, 14, 26, 22) size:13 bold:NO color:SLSubtleColor() align:NSTextAlignmentLeft];
        self.repsField = [self makeField:CGRectMake(142, 8, 62, 34)];
        self.repsField.keyboardType = UIKeyboardTypeNumberPad;
        [self.contentView addSubview:self.repsField];
        self.repsLabel = [self makeLabel:CGRectMake(206, 14, 44, 22) size:13 bold:NO color:SLSubtleColor() align:NSTextAlignmentLeft];
        self.repsLabel.text = @"powt.";
        self.recordLabel = [self makeLabel:CGRectMake(38, 41, 200, 10) size:10 bold:YES color:SLAccentColor() align:NSTextAlignmentLeft];
        self.doneButton = SLGelButton(@"", 1, CGRectMake(262, 7, 48, 36));
        [self.contentView addSubview:self.doneButton];
    }
    return self;
}

- (void)setDone:(BOOL)done
{
    [self.doneButton setBackgroundImage:SLGelImage(done ? 3 : 1) forState:UIControlStateNormal];
    [self.doneButton setImage:SLCheckImage(done) forState:UIControlStateNormal];
    self.kgField.alpha = self.repsField.alpha = done ? 0.75f : 1.0f;
}

@end

/* ---------- kafelek statystyki ---------- */

@implementation SLStatView

- (id)initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f])) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setValue:(NSString *)v { _value = [v copy]; [self setNeedsDisplay]; }
- (void)setCaption:(NSString *)v { _caption = [v copy]; [self setNeedsDisplay]; }

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = CGRectInset(self.bounds, 0.5f, 0.5f);
    UIBezierPath *shape = [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:10];
    CGContextSaveGState(c);
    [shape addClip];
    Gradient(c, self.bounds, C(74, 78, 88, 1), C(30, 32, 37, 1));
    /* odbicie: szklany połysk na górnej połowie */
    Gradient(c, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height * 0.5f), C(255, 255, 255, 0.22f), C(255, 255, 255, 0.04f));
    CGContextRestoreGState(c);
    [C(0, 0, 0, 0.9f) setStroke];
    [shape stroke];
    [C(255, 255, 255, 0.16f) setFill];
    CGContextFillRect(c, CGRectMake(8, 1, self.bounds.size.width - 16, 1));

    CGFloat w = self.bounds.size.width;
    CGContextSetShadowWithColor(c, CGSizeMake(0, -1), 0, C(0, 0, 0, 0.9f).CGColor);
    [[UIColor whiteColor] set];
    CGFloat size = 24.0f;
    UIFont *vf = [UIFont boldSystemFontOfSize:size];
    /* zmniejsz czcionkę, jeśli wartość się nie mieści */
    while (size > 12.0f && [_value sizeWithFont:vf].width > w - 10) { size -= 1.0f; vf = [UIFont boldSystemFontOfSize:size]; }
    [_value drawInRect:CGRectMake(4, 16, w - 8, 30) withFont:vf lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    [SLAccentColor() set];
    [[_caption uppercaseString] drawInRect:CGRectMake(2, 54, w - 4, 16) withFont:[UIFont boldSystemFontOfSize:11] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
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
    CGRect b = CGRectInset(self.bounds, 0, 0);
    /* panel */
    UIBezierPath *panel = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 0.5f, 0.5f) cornerRadius:8];
    CGContextSaveGState(c);
    [panel addClip];
    Gradient(c, b, C(18, 19, 23, 1), C(30, 32, 37, 1));
    CGContextRestoreGState(c);
    [C(0, 0, 0, 0.9f) setStroke];
    [panel stroke];

    NSArray *vals = self.values;
    CGFloat left = 40, right = 12, top = 14, bottom = 28;
    CGRect plot = CGRectMake(left, top, b.size.width - left - right, b.size.height - top - bottom);
    if ([vals count] == 0) {
        [SLSubtleColor() set];
        [@"Brak danych" drawInRect:CGRectMake(0, b.size.height / 2 - 9, b.size.width, 18) withFont:[UIFont systemFontOfSize:14] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentCenter];
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
        [C(255, 255, 255, 0.07f) setFill];
        CGContextFillRect(c, CGRectMake(plot.origin.x, (CGFloat)((int)y), plot.size.width, 1));
        double v = hi - (hi - lo) * i / 3.0;
        [SLSubtleColor() set];
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
    /* wypełnienie pod linią */
    if (n > 1) {
        UIBezierPath *area = [UIBezierPath bezierPathWithCGPath:line.CGPath];
        CGPoint last = [[pts lastObject] CGPointValue], first = [[pts objectAtIndex:0] CGPointValue];
        [area addLineToPoint:CGPointMake(last.x, plot.origin.y + plot.size.height)];
        [area addLineToPoint:CGPointMake(first.x, plot.origin.y + plot.size.height)];
        [area closePath];
        [C(255, 138, 0, 0.18f) setFill];
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
    [SLSubtleColor() set];
    NSArray *lb = self.labels;
    if ([lb count] >= 1) [[lb objectAtIndex:0] drawInRect:CGRectMake(plot.origin.x - 20, b.size.height - 20, 110, 14) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentLeft];
    if ([lb count] >= 2) [[lb objectAtIndex:1] drawInRect:CGRectMake(b.size.width - right - 110, b.size.height - 20, 110 + 8, 14) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
}

@end
