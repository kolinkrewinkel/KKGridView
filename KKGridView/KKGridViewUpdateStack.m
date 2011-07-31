//
//  KKGridViewUpdateStack.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewUpdateStack.h"
#import "KKGridViewUpdate.h"

@interface KKGridViewUpdateStack ()

- (void)_sortItems;

@end

@implementation KKGridViewUpdateStack

@synthesize itemsToUpdate = _itemsToUpdate;

- (id)init
{
    if ((self = [super init])) {
        _itemsToUpdate = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#ifndef KK_ARC_ON
- (void)dealloc
{
    [_itemsToUpdate release], _itemsToUpdate = nil;
    [super dealloc];
}
#endif

- (void)addUpdates:(NSArray *)updates
{
    for (KKGridViewUpdate *update in updates) {
        [self addUpdate:update];
    }
}

- (BOOL)addUpdate:(KKGridViewUpdate *)update
{
    if (![_itemsToUpdate containsObject:update]) {
        [_itemsToUpdate addObject:update];
        [self _sortItems];
        return YES;
    }
    
    return NO;
}

- (BOOL)removeUpdateForIndexPath:(KKIndexPath *)indexPath
{
    [_itemsToUpdate removeObject:[self updateForIndexPath:indexPath]];
    
    return YES;
}

- (void)_sortItems
{
    [_itemsToUpdate sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:NO]]];
}

- (KKGridViewUpdate *)updateForIndexPath:(KKIndexPath *)indexPath
{
    return [[[NSSet setWithArray:_itemsToUpdate] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"indexPath = %@", indexPath]] anyObject];
}

- (BOOL)hasUpdateForIndexPath:(KKIndexPath *)indexPath
{
    if (_itemsToUpdate.count == 0) return NO;
    
    for (KKGridViewUpdate *update in _itemsToUpdate) {
        if ([update.indexPath isEqual:indexPath]) {
            return YES;
        }
    }
    
    return NO;
}

@end
