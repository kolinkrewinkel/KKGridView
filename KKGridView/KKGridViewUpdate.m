//
//  KKGridViewUpdate.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewUpdate.h"

@implementation KKGridViewUpdate

@synthesize animation = _animation;
@synthesize indexPath = _indexPath;
@synthesize sectionUpdate = _sectionUpdate;
@synthesize type = _type;

- (void)dealloc
{
    [_indexPath release];
    [super dealloc];
}

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
    return [[[[self class] alloc] initWithIndexPath:indexPath isSectionUpdate:sectionUpdate type:type animation:animation] autorelease];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"KKGridViewUpdate - IndexPath: %@, Type: %d, Section Update: %i", _indexPath, _type, _sectionUpdate];
}

@end
