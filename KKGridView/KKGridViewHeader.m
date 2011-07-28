//
//  KKGridViewHeader.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.28.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import "KKGridViewHeader.h"

static UIFont *boldFont = nil;

@implementation KKGridViewHeader

@synthesize section = _section;
@synthesize sticking = _sticking;
@synthesize stickPoint = _stickPoint;
@synthesize debugText = _debugText;

+ (void)initialize
{
    boldFont = [UIFont boldSystemFontOfSize:13.f];
}

- (void)setDebugText:(NSString *)debugText
{
    [_debugText release];
    _debugText = [debugText copy];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (_debugText) {
        [_debugText drawInRect:CGRectInset(self.bounds, 0.f, 3.f) withFont:boldFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter]; 
    }
}

@end
