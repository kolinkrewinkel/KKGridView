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
@synthesize timestamp = _timestamp;
@synthesize destinationPath = _destinationPath;
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
    return [[self alloc] initWithIndexPath:indexPath 
                           isSectionUpdate:sectionUpdate
                                      type:type
                                 animation:animation];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"KKGridViewUpdate - IndexPath: %@, Type: %d, Section Update: %i",
            _indexPath, _type, _sectionUpdate];
}

- (BOOL)isEqual:(KKGridViewUpdate *)update
{
    return [_indexPath isEqual:update.indexPath] && _sectionUpdate == update.sectionUpdate && _type == update.type && _animation == update.animation;
}

- (KKGridViewUpdateSign)sign
{
    static BOOL const isNegative[KKGridViewUpdateTypeSectionReload + 1] = {
        [KKGridViewUpdateTypeItemDelete] = YES,
        [KKGridViewUpdateTypeSectionDelete] = YES
    };

    return isNegative[self.type] ? KKGridViewUpdateSignNegative : KKGridViewUpdateSignPositive;
}

- (NSUInteger)hash
{
    return _indexPath.hash * self.animation;
}

@end
