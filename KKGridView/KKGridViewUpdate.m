//
//  KKGridViewUpdate.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewUpdate.h"

@implementation KKGridViewUpdate

@synthesize indexPath = _indexPath;
@synthesize sectionUpdate = _sectionUpdate;
@synthesize type = _type;

- (void)dealloc
{
    [_indexPath release];
    [super dealloc];
}

@end
