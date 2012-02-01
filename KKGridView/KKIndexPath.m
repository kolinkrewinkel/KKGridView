//
//  KKIndexPath.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKIndexPath.h>

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

- (NSComparisonResult)compare:(KKIndexPath *)otherIndexPath
{
    // Identical comparison
    if (otherIndexPath.section == self.section && otherIndexPath.index == self.index) {
        return NSOrderedSame;
    }
    
    // Sectional comparison
    if (otherIndexPath.section > self.section) {
        return NSOrderedAscending;
    } else if (otherIndexPath.section < self.section) {
        return NSOrderedDescending;
    }
    
    // Inter-section index comparison
    if (otherIndexPath.index > self.index) {
        return NSOrderedAscending;
    } else if (otherIndexPath.index < self.index) {
        return NSOrderedDescending;
    }
    
    // No result could be found (this should never happen, kept in to keep the compiler happy)
    return NSOrderedSame;
}

+ (id)indexPathForIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    return [[self alloc] initWithIndex:index section:section];
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
    return [[self alloc] initWithNSIndexPath:indexPath];
}

- (BOOL)isEqual:(KKIndexPath *)indexPath
{
    return indexPath.index == self.index && indexPath.section == self.section;
}

- (NSUInteger)hash
{
    return _section + 7 * _index;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithIndex:_index section:_section];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {Index: %i; Section: %i}", 
            NSStringFromClass([self class]), _index, _section];
}

#pragma mark - KKIndexPath to NSIndexPath

- (NSIndexPath *)NSIndexPath {
    return [NSIndexPath indexPathForRow:self.index inSection:self.section];
}

@end
