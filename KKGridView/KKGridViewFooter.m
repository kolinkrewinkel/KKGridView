//
//  KKGridViewFooter.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.31.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import "KKGridViewFooter.h"

@implementation KKGridViewFooter
@synthesize view = _view;

- (id)initWithView:(UIView *)view
{
    if ((self = [super init])) {
        _view = view;
    }
    
    return self;
}

@end
