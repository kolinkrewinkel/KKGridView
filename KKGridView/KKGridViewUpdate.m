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

#ifndef KK_ARC_ON
- (void)dealloc
{
    [_indexPath release];
    [super dealloc];
}
#endif

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
#ifndef KK_ARC_ON
    [retVal autorelease];
#endif
    return retVal;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"KKGridViewUpdate - IndexPath: %@, Type: %d, Section Update: %i", _indexPath, _type, _sectionUpdate];
}

@end
