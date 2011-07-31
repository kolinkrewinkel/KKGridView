//
//  KKGridViewHeader.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.28.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewHeader.h"

@implementation KKGridViewHeader

@synthesize view = _view;

- (id)initWithView:(UIView *)view
{
    if ((self = [super init]))
    {
#ifndef KK_ARC_ON
        _view = [view retain];
#else
        _view = view;
#endif
    }
    
    return self;
}

#ifndef KK_ARC_ON
- (void)dealloc
{
    [_view release];
    [super dealloc];
}
#endif

@end
