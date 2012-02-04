//
//  KKGridViewUpdateStack.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewUpdateStack.h>
#import <KKGridView/KKGridViewUpdate.h>

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

- (void)removeUpdateForIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewUpdate *update = [self updateForIndexPath:indexPath];
    [self removeUpdate:update];
}

- (void)removeUpdate:(KKGridViewUpdate *)update
{
    [_itemsToUpdate removeObject:update];
}

- (void)_sortItems
{
    [_itemsToUpdate sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:YES]]];
}

- (KKGridViewUpdate *)updateForIndexPath:(KKIndexPath *)indexPath
{   
    NSPredicate *sameIndexPath = [NSPredicate predicateWithFormat:@"indexPath = %@", indexPath];
    return [[_itemsToUpdate filteredArrayUsingPredicate:sameIndexPath] objectAtIndex:0];
}

- (BOOL)hasUpdateForIndexPath:(KKIndexPath *)indexPath
{
    NSUInteger count = _itemsToUpdate.count;

    if (count == 0)
        return NO;
    
    for (NSUInteger i = 0; i < count; i++) {
        KKGridViewUpdate *update = [_itemsToUpdate objectAtIndex:i];
        if (!update.animating && [update.indexPath isEqual:indexPath]) {
            return YES;
        }
    }
    
    return NO;
}

- (KKIndexPath *)nextUpdateFromIndexPath:(KKIndexPath *)indexPath fallbackPath:(KKIndexPath *)fallback;
{
    [self _sortItems];
    NSUInteger index = [_itemsToUpdate indexOfObject:[self updateForIndexPath:indexPath]];
    if ([_itemsToUpdate count] > (index + 1)) {
        KKGridViewUpdate *update = [_itemsToUpdate objectAtIndex:index + 1];
        return update.indexPath;
    }
    
    return fallback;
}

@end
