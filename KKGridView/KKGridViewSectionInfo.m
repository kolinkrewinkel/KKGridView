//
//  KKGridViewSectionInfo.m
//  KKGridView
//
//  Created by Jonathan Sterling on 7/31/11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewSectionInfo.h>

@implementation KKGridViewSectionInfo

@synthesize view = _view;

- (id)initWithView:(UIView *)view
{
    if ((self = [super init])) {
        _view = view;
    }
    
    return self;
}

@end
