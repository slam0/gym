#import "SLViews.h"
#import "SLTheme.h"
#import "SLLang.h"

static UIColor *C(int r, int g, int b, CGFloat a)
{
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a];
}

/* kolor obrysu paneli: czarny, a w Game Center żółta ramka */
static UIColor *PanelBorder(const SLPalette *p)
{
    if (p->gc) return C(236, 230, 104, 0.95f);
    return C(0, 0, 0, p->light ? 0.4f : 0.9f);
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
@property (nonatomic) BOOL chevron;       /* Game Center: strzałka ">" po prawej */
@property (nonatomic) int position;       /* Game Center: 0 pierwszy w sekcji, 1 środkowy, 2 ostatni, 3 jedyny */
- (void)refreshPosition;
@end

@implementation SLGlossBackground
- (id)initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f])) {
        BOOL gc = SLGameCenter();
        self.opaque = !gc;
        self.backgroundColor = gc ? [UIColor clearColor] : nil;
        self.contentMode = UIViewContentModeRedraw;
        _position = 1;
    }
    return self;
}

- (void)setChevron:(BOOL)v { if (v != _chevron) { _chevron = v; [self setNeedsDisplay]; } }
- (void)setPosition:(int)v { if (v != _position) { _position = v; [self setNeedsDisplay]; } }

/* Game Center: wiersze tworzą zaokrąglone grupy, więc tło musi wiedzieć, czy wiersz jest pierwszy, środkowy czy ostatni */
- (void)refreshPosition
{
    if (!SLGameCenter()) return;
    UIView *cell = self.superview;
    if (![cell isKindOfClass:[UITableViewCell class]]) return;
    UIView *v = cell.superview;
    while (v && ![v isKindOfClass:[UITableView class]]) v = v.superview;
    UITableView *t = (UITableView *)v;
    if (!t || !t.dataSource) return;
    NSIndexPath *ip = [t indexPathForCell:(UITableViewCell *)cell];
    if (!ip) return;
    NSInteger n = [t.dataSource tableView:t numberOfRowsInSection:ip.section];
    self.position = n <= 1 ? 3 : (ip.row == 0 ? 0 : (ip.row == n - 1 ? 2 : 1));
}

- (void)drawGameCenter:(CGContextRef)c
{
    CGRect b = self.bounds;
    const CGFloat inset = 9.0f, r = 9.0f;
    CGFloat x0 = inset + 0.5f, x1 = b.size.width - inset - 0.5f, y0 = 0.5f, y1 = b.size.height - 0.5f;
    BOOL top = (_position == 0 || _position == 3), bot = (_position == 2 || _position == 3);
    /* wypełnienie: lekki połysk na sukni */
    UIRectCorner corners = (top ? (UIRectCornerTopLeft | UIRectCornerTopRight) : 0) | (bot ? (UIRectCornerBottomLeft | UIRectCornerBottomRight) : 0);
    CGRect fr = CGRectMake(x0, top ? y0 : 0, x1 - x0, (bot ? y1 : b.size.height) - (top ? y0 : 0));
    UIBezierPath *panel = corners ? [UIBezierPath bezierPathWithRoundedRect:fr byRoundingCorners:corners cornerRadii:CGSizeMake(r, r)]
                                  : [UIBezierPath bezierPathWithRect:fr];
    CGContextSaveGState(c);
    [panel addClip];
    if (_selected) {
        Gradient(c, b, C(255, 244, 130, 0.38f), C(255, 232, 90, 0.26f));
    } else {
        Gradient(c, b, C(255, 255, 255, 0.07f), C(0, 0, 0, 0.05f));
    }
    CGContextRestoreGState(c);
    /* żółta ramka: boki, góra (łuk albo linia rozdzielająca) i dół */
    [C(236, 230, 104, 0.95f) setStroke];
    CGContextSetLineWidth(c, 1.0f);
    CGContextBeginPath(c);
    CGFloat ly0 = top ? y0 + r : 0, ly1 = bot ? y1 - r : b.size.height;
    if (top) {
        CGContextMoveToPoint(c, x0, y0 + r);
        CGContextAddArcToPoint(c, x0, y0, x0 + r, y0, r);
        CGContextAddLineToPoint(c, x1 - r, y0);
        CGContextAddArcToPoint(c, x1, y0, x1, y0 + r, r);
    } else {
        CGContextMoveToPoint(c, x0, y0);
        CGContextAddLineToPoint(c, x1, y0);
    }
    CGContextMoveToPoint(c, x0, ly0);
    CGContextAddLineToPoint(c, x0, ly1);
    CGContextMoveToPoint(c, x1, ly0);
    CGContextAddLineToPoint(c, x1, ly1);
    if (bot) {
        CGContextMoveToPoint(c, x0, y1 - r);
        CGContextAddArcToPoint(c, x0, y1, x0 + r, y1, r);
        CGContextAddLineToPoint(c, x1 - r, y1);
        CGContextAddArcToPoint(c, x1, y1, x1, y1 - r, r);
    }
    CGContextStrokePath(c);
    if (_chevron) {                                   /* żółta strzałka ">" */
        CGFloat cx = x1 - 14.0f, cy = b.size.height / 2.0f;
        CGContextSetLineWidth(c, 2.8f);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextBeginPath(c);
        CGContextMoveToPoint(c, cx - 3.5f, cy - 6.0f);
        CGContextAddLineToPoint(c, cx + 2.5f, cy);
        CGContextAddLineToPoint(c, cx - 3.5f, cy + 6.0f);
        CGContextStrokePath(c);
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (SLGameCenter()) { [self drawGameCenter:c]; return; }
    CGRect b = self.bounds;
    CGFloat half = (CGFloat)((int)(b.size.height / 2.0f));
    const SLPalette *p = SLP();
    if (_selected) {
        Gradient(c, CGRectMake(0, 0, b.size.width, half), SLRGB(p->selT1, 1), SLRGB(p->selT2, 1));
        Gradient(c, CGRectMake(0, half, b.size.width, b.size.height - half), SLRGB(p->selB1, 1), SLRGB(p->selB2, 1));
    } else {
        Gradient(c, CGRectMake(0, 0, b.size.width, half), SLRGB(p->cellT1, 1), SLRGB(p->cellT2, 1));
        Gradient(c, CGRectMake(0, half, b.size.width, b.size.height - half), SLRGB(p->cellB1, 1), SLRGB(p->cellB2, 1));
    }
    [C(255, 255, 255, p->cellHiAlpha) setFill];
    CGContextFillRect(c, CGRectMake(0, 0, b.size.width, 1));
    [C(0, 0, 0, p->cellLoAlpha) setFill];
    CGContextFillRect(c, CGRectMake(0, b.size.height - 1, b.size.width, 1));
}
@end

@interface SLCell ()
{
    BOOL _chevron;
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
        SLStyleShadow(self.textLabel);
        self.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.textColor = SLSubtleColor();
        self.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        if (SLGameCenter()) {                         /* tytuły szeryfowe, podpisy ciemnozielone jak w Game Center */
            UIFont *serif = [UIFont fontWithName:@"Georgia-Bold" size:17.0f];
            if (serif) self.textLabel.font = serif;
            self.detailTextLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.20f];
            self.detailTextLabel.shadowOffset = CGSizeMake(0, 1);
        }
    }
    return self;
}

/* Game Center: strzałkę ">" rysuje tło wiersza (żółta, wewnątrz ramki), więc systemową wyłączamy */
- (void)setAccessoryType:(UITableViewCellAccessoryType)type
{
    BOOL chev = SLGameCenter() && type == UITableViewCellAccessoryDisclosureIndicator;
    _chevron = chev;
    [super setAccessoryType:chev ? UITableViewCellAccessoryNone : type];
    [(SLGlossBackground *)self.backgroundView setChevron:chev];
    [(SLGlossBackground *)self.selectedBackgroundView setChevron:chev];
}

- (void)syncGameCenterBackgrounds
{
    SLGlossBackground *bg = (SLGlossBackground *)self.backgroundView;
    SLGlossBackground *sel = (SLGlossBackground *)self.selectedBackgroundView;
    [bg refreshPosition];
    sel.position = bg.position;
    sel.chevron = _chevron;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!SLGameCenter()) return;
    [self syncGameCenterBackgrounds];
    /* treść mieści się wewnątrz ramki (9 pt odstępu z każdej strony, miejsce na strzałkę) */
    CGFloat inset = 9.0f, right = inset + (_chevron ? 22.0f : 0.0f);
    CGRect cf = self.contentView.frame;
    cf.origin.x += inset;
    cf.size.width -= inset + right;
    self.contentView.frame = cf;
    if (self.accessoryView) {                         /* np. "ptaszek" wyboru: wewnątrz ramki */
        CGRect af = self.accessoryView.frame;
        af.origin.x -= inset + 4.0f;
        self.accessoryView.frame = af;
    }
    CGFloat shift = self.imageView.image ? 8.0f : 0.0f;
    UIView *kids[3] = { self.imageView, self.textLabel, self.detailTextLabel };
    for (int i = 0; i < 3; i++) {
        UIView *v = kids[i];
        CGRect f = v.frame;
        f.origin.x += shift;
        CGFloat maxX = cf.size.width - 6.0f;
        if (f.origin.x < maxX && CGRectGetMaxX(f) > maxX && i > 0) f.size.width = maxX - f.origin.x;
        v.frame = f;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (SLGameCenter()) [self syncGameCenterBackgrounds];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (SLGameCenter()) [self syncGameCenterBackgrounds];
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
    if ((self = [super initWithFrame:CGRectMake(0, 0, 320, SLHeaderHeight())])) {
        _title = [title copy];
        _right = [right copy];
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}
/* ozdoba nagłówka Game Center: podwójna strzałka (w prawo ">>" po lewej stronie tytułu, "<<" po prawej) */
static void DrawOrnament(CGContextRef c, CGFloat x, CGFloat midY, BOOL mirrored)
{
    CGContextSaveGState(c);
    CGContextSetLineWidth(c, 2.2f);
    CGContextSetLineCap(c, kCGLineCapSquare);
    CGContextSetLineJoin(c, kCGLineJoinMiter);
    for (int i = 0; i < 2; i++) {
        CGFloat ox = x + i * 6.0f;
        CGFloat dir = mirrored ? -1.0f : 1.0f;
        CGFloat bx = mirrored ? ox + 6.0f : ox;
        CGContextBeginPath(c);
        CGContextMoveToPoint(c, bx, midY - 6.0f);
        CGContextAddLineToPoint(c, bx + dir * 6.0f, midY);
        CGContextAddLineToPoint(c, bx, midY + 6.0f);
        CGContextStrokePath(c);
    }
    CGContextRestoreGState(c);
}

- (void)drawGameCenter:(CGContextRef)c
{
    CGRect b = self.bounds;
    UIFont *f = [UIFont fontWithName:@"Georgia-Bold" size:17.0f];
    if (!f) f = [UIFont boldSystemFontOfSize:17.0f];
    CGContextSetShadowWithColor(c, CGSizeMake(0, -1), 0, C(0, 40, 20, 0.55f).CGColor);
    UIColor *yellow = C(232, 226, 100, 1);
    [yellow set];
    [yellow setStroke];
    CGFloat lineH = f.lineHeight, ty = (CGFloat)((int)((b.size.height - lineH) / 2.0f)) + 4.0f;
    if ([_right length]) {
        UIFont *sm = [UIFont fontWithName:@"Georgia-Bold" size:14.0f];
        if (!sm) sm = [UIFont boldSystemFontOfSize:14.0f];
        [_title drawInRect:CGRectMake(14, ty, b.size.width - 130, lineH) withFont:f lineBreakMode:NSLineBreakByTruncatingTail];
        [_right drawInRect:CGRectMake(b.size.width - 130, ty + 2, 116, lineH) withFont:sm lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentRight];
        return;
    }
    CGFloat maxW = b.size.width - 2.0f * 54.0f;
    CGFloat w = [_title sizeWithFont:f].width;
    if (w > maxW) w = maxW;
    CGFloat tx = (CGFloat)((int)((b.size.width - w) / 2.0f));
    [_title drawInRect:CGRectMake(tx, ty, w, lineH) withFont:f lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentCenter];
    CGFloat midY = ty + lineH / 2.0f + 1.0f;
    DrawOrnament(c, tx - 28.0f, midY, NO);
    DrawOrnament(c, tx + w + 10.0f, midY, YES);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    const SLPalette *p = SLP();
    if (p->gc) { [self drawGameCenter:c]; return; }
    Gradient(c, b, SLRGB(p->hdrT, 0.97f), SLRGB(p->hdrB, 0.97f));
    [C(255, 255, 255, p->light ? 0.35f : 0.10f) setFill];
    CGContextFillRect(c, CGRectMake(0, 0, b.size.width, 1));
    [C(0, 0, 0, 0.8f) setFill];
    CGContextFillRect(c, CGRectMake(0, b.size.height - 1, b.size.width, 1));
    UIFont *f = [UIFont boldSystemFontOfSize:13.0f];
    CGContextSetShadowWithColor(c, CGSizeMake(0, -1), 0, C(0, 0, 0, p->light ? 0.45f : 0.9f).CGColor);
    [SLRGB(p->hdrTitle, 1) set];
    [_title drawInRect:CGRectMake(12, 5, b.size.width - 100, 18) withFont:f lineBreakMode:NSLineBreakByTruncatingTail];
    if ([_right length]) {
        [SLRGB(p->hdrRight, 1) set];
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
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:GL(@"Gotowe") style:UIBarButtonItemStyleDone target:target action:doneAction];
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
        [SLSubtleColor() setStroke];
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
    static NSInteger forTheme = -1;
    if (img && forTheme == SLCurrentTheme()) return img;
    forTheme = SLCurrentTheme();
    const SLPalette *p = SLP();
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 34), NO, 0.0f);
    CGContextRef c = UIGraphicsGetCurrentContext();
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, 19, 32) cornerRadius:7];
    CGContextSaveGState(c);
    [path addClip];
    Gradient(c, CGRectMake(0, 0, 20, 34), SLRGB(p->fieldT, 1), SLRGB(p->fieldB, 1));
    CGContextRestoreGState(c);
    [PanelBorder(p) setStroke];
    [path stroke];
    [C(255, 255, 255, p->light ? 0.8f : 0.12f) setFill];
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
    f.textColor = SLRGB(SLP()->fieldText, 1);
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
    SLStyleShadow(l);
    [self.contentView addSubview:l];
    return l;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuse
{
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuse])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundView = [[SLGlossBackground alloc] initWithFrame:self.bounds];
        /* w Game Center wiersz leży w ramce z 9 pt odstępu, więc elementy są trochę ciaśniej */
        BOOL gc = SLGameCenter();
        self.numLabel = [self makeLabel:(gc ? CGRectMake(12, 14, 26, 22) : CGRectMake(6, 14, 28, 22)) size:16 bold:YES color:SLSubtleColor() align:NSTextAlignmentCenter];
        self.kgField = [self makeField:(gc ? CGRectMake(40, 8, 70, 34) : CGRectMake(38, 8, 74, 34))];
        self.kgField.keyboardType = UIKeyboardTypeDecimalPad;
        [self.contentView addSubview:self.kgField];
        self.unitLabel = [self makeLabel:(gc ? CGRectMake(112, 14, 24, 22) : CGRectMake(114, 14, 26, 22)) size:13 bold:NO color:SLSubtleColor() align:NSTextAlignmentLeft];
        self.repsField = [self makeField:(gc ? CGRectMake(138, 8, 58, 34) : CGRectMake(142, 8, 62, 34))];
        self.repsField.keyboardType = UIKeyboardTypeNumberPad;
        [self.contentView addSubview:self.repsField];
        self.repsLabel = [self makeLabel:(gc ? CGRectMake(198, 14, 40, 22) : CGRectMake(206, 14, 44, 22)) size:13 bold:NO color:SLSubtleColor() align:NSTextAlignmentLeft];
        self.repsLabel.text = GL(@"powt.");
        self.recordLabel = [self makeLabel:(gc ? CGRectMake(40, 41, 200, 10) : CGRectMake(38, 41, 200, 10)) size:10 bold:YES color:SLAccentColor() align:NSTextAlignmentLeft];
        self.doneButton = SLGelButton(@"", 1, gc ? CGRectMake(250, 7, 48, 36) : CGRectMake(262, 7, 48, 36));
        [self.contentView addSubview:self.doneButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (SLGameCenter()) [(SLGlossBackground *)self.backgroundView refreshPosition];
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
    const SLPalette *p = SLP();
    Gradient(c, self.bounds, SLRGB(p->tileT, 1), SLRGB(p->tileB, 1));
    /* odbicie: szklany połysk na górnej połowie */
    Gradient(c, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height * 0.5f), C(255, 255, 255, p->light ? 0.55f : 0.22f), C(255, 255, 255, p->light ? 0.10f : 0.04f));
    CGContextRestoreGState(c);
    [PanelBorder(p) setStroke];
    [shape stroke];
    [C(255, 255, 255, 0.16f) setFill];
    CGContextFillRect(c, CGRectMake(8, 1, self.bounds.size.width - 16, 1));

    CGFloat w = self.bounds.size.width;
    CGContextSetShadowWithColor(c, CGSizeMake(0, p->shadowDY), 0, SLRGB(p->shadow, p->light ? 0.9f : 0.9f).CGColor);
    [SLRGB(p->tileText, 1) set];
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
    const SLPalette *p = SLP();
    Gradient(c, b, SLRGB(p->panelT, 1), SLRGB(p->panelB, 1));
    CGContextRestoreGState(c);
    [PanelBorder(p) setStroke];
    [panel stroke];

    NSArray *vals = self.values;
    CGFloat left = 40, right = 12, top = 14, bottom = 28;
    CGRect plot = CGRectMake(left, top, b.size.width - left - right, b.size.height - top - bottom);
    if ([vals count] == 0) {
        [SLSubtleColor() set];
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
        [SLRGB(p->grid, p->gridAlpha) setFill];
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
        [SLRGB(p->accent, 0.18f) setFill];
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



/* ---------- wykres słupkowy ---------- */

@implementation SLBarChartView

- (id)initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f])) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setValues:(NSArray *)v { _values = [v copy]; [self setNeedsDisplay]; }
- (void)setLabels:(NSArray *)v { _labels = [v copy]; [self setNeedsDisplay]; }

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    const SLPalette *p = SLP();
    UIBezierPath *panel = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 0.5f, 0.5f) cornerRadius:8];
    CGContextSaveGState(c);
    [panel addClip];
    Gradient(c, b, SLRGB(p->panelT, 1), SLRGB(p->panelB, 1));
    CGContextRestoreGState(c);
    [PanelBorder(p) setStroke];
    [panel stroke];

    NSUInteger n = [_values count];
    if (n == 0) return;
    double mx = 0;
    for (NSNumber *v in _values) if ([v doubleValue] > mx) mx = [v doubleValue];
    if (mx <= 0) mx = 1;
    CGFloat left = 8, right = 8, top = 20, bottom = 22;
    CGRect plot = CGRectMake(left, top, b.size.width - left - right, b.size.height - top - bottom);
    CGFloat slot = plot.size.width / n, bw = slot * 0.62f;
    UIFont *small = [UIFont systemFontOfSize:10];
    for (NSUInteger i = 0; i < n; i++) {
        double v = [[_values objectAtIndex:i] doubleValue];
        CGFloat h = (CGFloat)(v / mx) * plot.size.height;
        if (v > 0 && h < 3) h = 3;
        CGRect bar = CGRectMake(plot.origin.x + slot * i + (slot - bw) / 2, plot.origin.y + plot.size.height - h, bw, h);
        if (v > 0) {
            UIBezierPath *bp = [UIBezierPath bezierPathWithRoundedRect:bar byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(3, 3)];
            [SLRGB(p->accent, i == n - 1 ? 1.0f : 0.65f) setFill];
            [bp fill];
        }
        [SLRGB(p->grid, 0.9f) setFill];
        CGContextFillRect(c, CGRectMake(plot.origin.x + slot * i + 1, plot.origin.y + plot.size.height, slot - 2, 1));
        if (v > 0) {
            [SLTextColor() set];
            NSString *t = SLNumberString(v);
            [t drawInRect:CGRectMake(plot.origin.x + slot * i - 4, bar.origin.y - 13, slot + 8, 12) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
        }
        if (i < [_labels count]) {
            [SLSubtleColor() set];
            [[_labels objectAtIndex:i] drawInRect:CGRectMake(plot.origin.x + slot * i - 4, b.size.height - 18, slot + 8, 12) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
        }
    }
}

@end

/* ---------- kalendarz ---------- */

@implementation SLCalendarView

- (id)initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f])) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setYear:(NSInteger)y { _year = y; [self setNeedsDisplay]; }
- (void)setMonth:(NSInteger)m { _month = m; [self setNeedsDisplay]; }
- (void)setMarkedDays:(NSSet *)s { _markedDays = [s copy]; [self setNeedsDisplay]; }
- (void)setSelectedDay:(NSInteger)d { _selectedDay = d; [self setNeedsDisplay]; }

/* dni miesiąca i przesunięcie pierwszego dnia (pn = 0) */
- (void)layoutInfo:(NSInteger *)days offset:(NSInteger *)offset
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dc = [[NSDateComponents alloc] init];
    dc.year = _year; dc.month = _month; dc.day = 1;
    NSDate *first = [cal dateFromComponents:dc];
    *days = (NSInteger)[cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:first].length;
    NSInteger wd = [cal components:NSWeekdayCalendarUnit fromDate:first].weekday;      /* 1 = nd */
    *offset = (wd + 5) % 7;
}

- (CGFloat)headH { return 22; }

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    const SLPalette *p = SLP();
    UIBezierPath *panel = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 0.5f, 0.5f) cornerRadius:8];
    CGContextSaveGState(c);
    [panel addClip];
    Gradient(c, b, SLRGB(p->panelT, 1), SLRGB(p->panelB, 1));
    CGContextRestoreGState(c);
    [PanelBorder(p) setStroke];
    [panel stroke];
    if (_year <= 0) return;

    NSInteger days, offset;
    [self layoutInfo:&days offset:&offset];
    CGFloat cw = b.size.width / 7.0f, top = [self headH] + 4;
    NSInteger rows = (offset + days + 6) / 7;
    CGFloat ch = (b.size.height - top - 4) / (rows > 5 ? 6 : 5);
    UIFont *small = [UIFont boldSystemFontOfSize:11], *num = [UIFont boldSystemFontOfSize:15];
    NSArray *dn = [NSArray arrayWithObjects:GL(@"Pn"), GL(@"Wt"), GL(@"Śr"), GL(@"Cz"), GL(@"Pt"), GL(@"Sb"), GL(@"Nd"), nil];
    [SLSubtleColor() set];
    for (int i = 0; i < 7; i++)
        [[dn objectAtIndex:(NSUInteger)i] drawInRect:CGRectMake(cw * i, 6, cw, 14) withFont:small lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    NSInteger today = 0;
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *tc = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
    if (tc.year == _year && tc.month == _month) today = tc.day;
    for (NSInteger d = 1; d <= days; d++) {
        NSInteger idx = offset + d - 1;
        CGRect cell = CGRectMake(cw * (idx % 7), top + ch * (idx / 7), cw, ch);
        CGRect dot = CGRectMake(cell.origin.x + cell.size.width / 2 - 15, cell.origin.y + cell.size.height / 2 - 15, 30, 30);
        BOOL marked = [_markedDays containsObject:[NSNumber numberWithInteger:d]];
        if (marked) {
            [SLRGB(p->accent, 1.0f) setFill];
            [[UIBezierPath bezierPathWithOvalInRect:dot] fill];
        } else if (d == today) {
            [SLAccentColor() setStroke];
            UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(dot, 1, 1)];
            ring.lineWidth = 1.5f;
            [ring stroke];
        }
        if (d == _selectedDay) {
            [SLTextColor() setStroke];
            UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(dot, -1, -1)];
            ring.lineWidth = 2.0f;
            [ring stroke];
        }
        [(marked ? [UIColor whiteColor] : SLTextColor()) set];
        [[NSString stringWithFormat:@"%ld", (long)d] drawInRect:CGRectMake(cell.origin.x, dot.origin.y + 6, cell.size.width, 20) withFont:num lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_year <= 0) return;
    CGPoint pt = [[touches anyObject] locationInView:self];
    NSInteger days, offset;
    [self layoutInfo:&days offset:&offset];
    CGFloat cw = self.bounds.size.width / 7.0f, top = [self headH] + 4;
    NSInteger rows = (offset + days + 6) / 7;
    CGFloat ch = (self.bounds.size.height - top - 4) / (rows > 5 ? 6 : 5);
    if (pt.y < top) return;
    NSInteger col = (NSInteger)(pt.x / cw), row = (NSInteger)((pt.y - top) / ch);
    NSInteger d = row * 7 + col - offset + 1;
    if (col < 0 || col > 6 || d < 1 || d > days) return;
    self.selectedDay = (d == _selectedDay) ? 0 : d;      /* drugie dotknięcie odznacza dzień */
    if (_target && _action && [_target respondsToSelector:_action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_action withObject:self];
#pragma clang diagnostic pop
    }
}

@end

/* ---------- zdjęcia ćwiczeń ---------- */

/* Wszystkie zdjęcia leżą w jednym pliku Resources/ex.pack (skleione JPEG-i), a spis w ex.plist: nazwa -> [początek, długość].
   Jeden plik zamiast 315 dużo ułatwia wgranie na GitHuba (przeglądarka przyjmuje najwyżej 100 plików naraz). */
static NSDictionary *SLPhotoIndex(void)
{
    static NSDictionary *idx = nil;
    static BOOL loaded = NO;
    if (!loaded) {
        loaded = YES;
        NSString *p = [[NSBundle mainBundle] pathForResource:@"ex" ofType:@"plist"];
        idx = p ? [NSDictionary dictionaryWithContentsOfFile:p] : nil;
    }
    return idx;
}

NSUInteger SLExercisePhotoCount(void) { return [SLPhotoIndex() count]; }

UIImage *SLExercisePhoto(NSString *exerciseId, int frame)
{
    static NSCache *cache = nil;
    static NSData *pack = nil;
    if (![exerciseId length]) return nil;
    NSDictionary *idx = SLPhotoIndex();
    if (!idx) return nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:160]; }
    NSString *key = [exerciseId stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    NSString *name = frame < 0 ? [key stringByAppendingString:@"_t"] : [NSString stringWithFormat:@"%@_%d", key, frame];
    id hit = [cache objectForKey:name];
    if (hit) return [hit isKindOfClass:[UIImage class]] ? hit : nil;
    UIImage *img = nil;
    NSArray *pos = [idx objectForKey:name];
    if ([pos count] == 2) {
        if (!pack) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"ex" ofType:@"pack"];
            pack = path ? [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:NULL] : nil;
        }
        NSUInteger off = [[pos objectAtIndex:0] unsignedIntegerValue], len = [[pos objectAtIndex:1] unsignedIntegerValue];
        if (pack && off + len <= [pack length]) img = [UIImage imageWithData:[pack subdataWithRange:NSMakeRange(off, len)]];
    }
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
