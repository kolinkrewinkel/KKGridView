//
//  KKGridViewHeader.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.28.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import "KKGridViewHeader.h"

@implementation KKGridViewHeader

@synthesize view = _view;
@synthesize section = _section;
@synthesize sticking = _sticking;
@synthesize stickPoint = _stickPoint;

- (void)dealloc
{
    [_view release];
    [super dealloc];
}

@end
