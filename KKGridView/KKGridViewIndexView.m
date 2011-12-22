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

#define KKGridViewIndexViewPadding 5.
#define KKGridViewIndexViewMargin 5.

@interface KKGridViewIndexView () {
    NSUInteger _lastTrackingSection;
    BOOL _tracking;
}

- (void)setTracking:(BOOL)tracking touch:(UITouch *)touch;
@end

@implementation KKGridViewIndexView

@synthesize sectionIndexTitles = _sectionIndexTitles;
@synthesize sectionTracked = _sectionTracked;

+ (void)initialize {
    if (self == [KKGridViewIndexView class]) {
        backgroundColor = [UIColor colorWithWhite:0. alpha:.25];
        fontColor = [UIColor colorWithWhite:0. alpha:.75];
        font = [UIFont boldSystemFontOfSize:12.];
    }
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setOpaque:NO];
        [self setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight)];
        [self setUserInteractionEnabled:YES];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Start");
    [self setTracking:YES touch:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Moved");    
    [self setTracking:YES touch:[touches anyObject]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Cancelled");    
    [self setTracking:NO touch:[touches anyObject]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Ended");
    [self setTracking:NO touch:[touches anyObject]];
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
                              0.,
                              self.frame.size.width,
                              newSuperview.bounds.size.height)];
}

#pragma mark - Setters

- (void)setSectionIndexTitles:(NSArray *)sectionIndexTitles {
    _sectionIndexTitles = sectionIndexTitles;
    
    // Look for the largest title and set the width
    CGFloat maxWidth = 0.;
    CGFloat currentWidth = 0.;
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

#pragma mark - Private

- (void)setTracking:(BOOL)tracking touch:(UITouch *)touch {
    _tracking = tracking;
    if (_tracking) {
        NSUInteger sections = [_sectionIndexTitles count];
        CGFloat sectionHeight = (self.bounds.size.height - 2*KKGridViewIndexViewMargin)/sections;
        CGPoint point = [touch locationInView:self];
        point.y-=KKGridViewIndexViewMargin;
    
        NSUInteger trackingSection = floorf(point.y/sectionHeight);
        if (trackingSection != _lastTrackingSection) {
            _lastTrackingSection = trackingSection;
            
            if (_sectionTracked)
                _sectionTracked(_lastTrackingSection);
        }
    }
    [self setNeedsDisplay];
}

@end
