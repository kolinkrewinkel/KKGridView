//
//  KKGridViewUpdate.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewUpdate.h>

@implementation KKGridViewUpdate

@synthesize animation = _animation;
@synthesize animating = _animating;
@synthesize indexPath = _indexPath;
@synthesize sectionUpdate = _sectionUpdate;
@synthesize type = _type;

- (id)initWithIndexPath:(KKIndexPath *)indexPath isSectionUpdate:(BOOL)sectionUpdate type:(KKGridViewUpdateType)type animation:(KKGridViewAnimation)animation
{
    if ((self = [super init])) {
        self.indexPath = indexPath;
        self.sectionUpdate = sectionUpdate;
        self.type = type;
        self.animation = animation;
    }
    
    return self;
}

+ (id)updateWithIndexPath:(KKIndexPath *)indexPath isSectionUpdate:(BOOL)sectionUpdate type:(KKGridViewUpdateType)type animation:(KKGridViewAnimation)animation
{
    id retVal = [[[self class] alloc] initWithIndexPath:indexPath isSectionUpdate:sectionUpdate type:type animation:animation];
    return retVal;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"KKGridViewUpdate - IndexPath: %@, Type: %d, Section Update: %i", _indexPath, _type, _sectionUpdate];
}

- (BOOL)isEqual:(id)object
{
    KKGridViewUpdate *update = (KKGridViewUpdate *)object;
    return ([_indexPath isEqual:update.indexPath] && _sectionUpdate == update.sectionUpdate && _type == update.type && _animation == update.animation);
}

- (NSUInteger)hash
{
    return _indexPath.hash * self.animation;
}

@end
