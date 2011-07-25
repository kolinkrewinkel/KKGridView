//
//  KKIndexPath.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import "KKIndexPath.h"

@implementation KKIndexPath

@synthesize index = _index;
@synthesize section = _section;

- (id)initWithIndex:(NSUInteger)index section:(NSUInteger)section
{
    if ((self = [super init])) {
        _index = index;
        _section = section;
    }
    
    return self;
}

+ (id)indexPathForIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    return [[[[self class] alloc] initWithIndex:index section:section] autorelease];
}

@end
