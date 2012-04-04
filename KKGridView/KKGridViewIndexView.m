//
//  KKGridViewIndexView.m
//  KKGridView
//
//  Created by Simon Blommegård on 2011-12-22.
//

#import "KKGridViewIndexView.h"

static UIColor *backgroundColor = nil;
static UIColor *fontColor = nil;
static UIFont *font = nil;

static CGFloat const KKGridViewIndexViewPadding = 7.0;
static CGFloat const KKGridViewIndexViewMargin = 7.0;

@interface KKGridViewIndexView () {
    NSUInteger _lastTrackingSection;
}
@end

@implementation KKGridViewIndexView

@synthesize sectionIndexTitles = _sectionIndexTitles;
@synthesize sectionTracked = _sectionTracked;
@synthesize tracking = _tracking;

+ (void)initialize {
    if (self == [KKGridViewIndexView class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
            fontColor = [UIColor colorWithWhite:0.0 alpha:0.75];
            font = [UIFont boldSystemFontOfSize:12.0];
        });
    }
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // If tracking, draw background
    if (_tracking) {
        [backgroundColor set];
        
        CGRect insetBounds = CGRectInset(self.bounds, KKGridViewIndexViewMargin, KKGridViewIndexViewMargin);
        CGFloat radius = (self.bounds.size.width - 2*KKGridViewIndexViewMargin) / 2;
        [[UIBezierPath bezierPathWithRoundedRect:insetBounds cornerRadius:radius] fill];
    }
    
    NSUInteger sections = [_sectionIndexTitles count];
    CGFloat sectionHeight = (self.bounds.size.height - 2 * KKGridViewIndexViewMargin)/sections;
    CGFloat currentSectionTop = KKGridViewIndexViewMargin;
    
    // Draw the titles in the center of its section
    [fontColor set];
    
    for (NSString *title in _sectionIndexTitles) {
        CGSize currentTitleSize = [title sizeWithFont:font];
        CGPoint drawingPoint = {
            floorf(self.bounds.size.width / 2 - currentTitleSize.width / 2),
            floorf(currentSectionTop + (sectionHeight / 2 - currentTitleSize.height / 2))
        };
        
        [title drawAtPoint:drawingPoint withFont:font];
        currentSectionTop+=sectionHeight;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    self.frame = (CGRect) {
        .origin.x = newSuperview.bounds.size.width - self.frame.size.width,
        .size.width = self.frame.size.width,
        .size.height = newSuperview.bounds.size.height
    };
}

#pragma mark - Setters

- (void)setSectionIndexTitles:(NSArray *)sectionIndexTitles {
    _sectionIndexTitles = sectionIndexTitles;
    
    // Look for the largest title and set the width
    CGFloat maxWidth = 0.0;
    
    for (NSString *title in _sectionIndexTitles) {
        CGFloat currentWidth = [title sizeWithFont:font].width;
        
        if (currentWidth > maxWidth)
            maxWidth = currentWidth;
    }
    
    CGSize size = { 
        maxWidth + 2*KKGridViewIndexViewPadding + 2*KKGridViewIndexViewMargin,
        self.frame.size.height
    };
    
    self.frame = (CGRect){self.frame.origin, size};
    [self setNeedsDisplay];
}

#pragma mark - Public

- (void)setTracking:(BOOL)tracking location:(CGPoint)location {
    _tracking = tracking;
    if (_tracking && CGRectContainsPoint(self.bounds, location)) {
        NSUInteger sections = [_sectionIndexTitles count];
        CGFloat sectionHeight = (self.bounds.size.height - 2*KKGridViewIndexViewMargin)/sections;
        location.y -= KKGridViewIndexViewMargin;
        
        _lastTrackingSection = floorf(abs(location.y)/sectionHeight);
        
        if (_lastTrackingSection == _sectionIndexTitles.count)
            _lastTrackingSection--;
        
        if (_sectionTracked)
            _sectionTracked(_lastTrackingSection);
    }
    
    [self setNeedsDisplay];
}


@end
