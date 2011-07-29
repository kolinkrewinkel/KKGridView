//
//  KKIndexPath.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
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

- (id)initWithNSIndexPath:(NSIndexPath *)indexPath 
{
    if ((self = [super init])) {
        self.index = indexPath.row;
        self.section = indexPath.section;
    }
    
    return self;
}

+ (id)indexPathWithNSIndexPath:(NSIndexPath *)indexPath 
{
    return [[[[self class] alloc] initWithNSIndexPath:indexPath] autorelease];
}

- (BOOL)isEqual:(id)object
{
    KKIndexPath *indexPath = (KKIndexPath *)object;
    if (indexPath.index == self.index && indexPath.section == self.section) {
        return YES;
    }
    
    return NO;
}

- (NSUInteger)hash {
    return _section + 7 * _index;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    id new = [[[self class] alloc] initWithIndex:_index section:_section];
    return new;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Index: %i; Section: %i", _index, _section];
}

@end
