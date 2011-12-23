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

#define KKGridViewIndexViewPadding 7.0
#define KKGridViewIndexViewMargin 7.0

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
        backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
        fontColor = [UIColor colorWithWhite:0.0 alpha:0.75];
        font = [UIFont boldSystemFontOfSize:12.0];
    }
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setOpaque:NO];
        [self setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight)];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // If tracking, draw background
    if (_tracking) {
        [backgroundColor set];    
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, KKGridViewIndexViewMargin, KKGridViewIndexViewMargin)
                                                        cornerRadius:(self.bounds.size.width-2*KKGridViewIndexViewMargin)/2];
        [path fill];
    }
    
    NSUInteger sections = [_sectionIndexTitles count];
    CGFloat sectionHeight = (self.bounds.size.height - 2*KKGridViewIndexViewMargin)/sections;
    CGFloat currentSectionTop = KKGridViewIndexViewMargin;
    
    // Draw the titles in the center of its section
    CGSize currentTitleSize;
    CGPoint drawingPoint;
    [fontColor set];
    for (NSString *title in _sectionIndexTitles) {
        currentTitleSize = [title sizeWithFont:font];
        drawingPoint = CGPointMake(floorf(self.bounds.size.width/2-currentTitleSize.width/2),
                                   floorf(currentSectionTop+(sectionHeight/2-currentTitleSize.height/2))),
        
        [title drawAtPoint:drawingPoint withFont:font];
        currentSectionTop+=sectionHeight;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [self setFrame:CGRectMake(newSuperview.bounds.size.width-self.frame.size.width,
                              0.0,
                              self.frame.size.width,
                              newSuperview.bounds.size.height)];
}

#pragma mark - Setters

- (void)setSectionIndexTitles:(NSArray *)sectionIndexTitles {
    _sectionIndexTitles = sectionIndexTitles;
    
    // Look for the largest title and set the width
    CGFloat maxWidth = 0.0;
    CGFloat currentWidth = 0.0;
    for (NSString *title in _sectionIndexTitles) {
        currentWidth = [title sizeWithFont:font].width;
        
        if (currentWidth > maxWidth)
            maxWidth = currentWidth;
    }
    
    [self setFrame:CGRectMake(self.frame.origin.x,
                              self.frame.origin.x,
                              maxWidth+(2*KKGridViewIndexViewPadding+2*KKGridViewIndexViewMargin),
                              self.frame.size.height)];
    
    [self setNeedsDisplay];
}

#pragma mark - Public

- (void)setTracking:(BOOL)tracking location:(CGPoint)location {
    _tracking = tracking;
    if (_tracking) {
        NSUInteger sections = [_sectionIndexTitles count];
        CGFloat sectionHeight = (self.bounds.size.height - 2*KKGridViewIndexViewMargin)/sections;
        location.y-=KKGridViewIndexViewMargin;
    
        _lastTrackingSection = floorf(abs(location.y)/sectionHeight);
        
        if (_sectionTracked)
            _sectionTracked(_lastTrackingSection);

    }
    [self setNeedsDisplay];
}


@end
