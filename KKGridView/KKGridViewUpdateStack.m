//
//  KKGridViewUpdateStack.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewUpdateStack.h>
#import <KKGridView/KKGridViewUpdate.h>

@interface KKGridViewUpdateStack () {
    CFMutableDictionaryRef _availableUpdates;
}

- (void)_sortItems;
- (BOOL)addUpdate:(KKGridViewUpdate *)update sortingAfterAdd:(BOOL) sortAfterAdd;

@end

@implementation KKGridViewUpdateStack

@synthesize itemsToUpdate = _itemsToUpdate;

- (id)init
{
    if ((self = [super init])) {
        _itemsToUpdate = [[NSMutableArray alloc] init];
        _availableUpdates = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    
    return self;
}

- (void)addUpdates:(NSArray *)updates
{
    for (KKGridViewUpdate *update in updates) {
        [self addUpdate:update sortingAfterAdd:NO];
    }
    [self _sortItems];
}

- (BOOL)addUpdate:(KKGridViewUpdate *)update
{
    return [self addUpdate:update sortingAfterAdd:YES];
}

- (BOOL)addUpdate:(KKGridViewUpdate *)update sortingAfterAdd:(BOOL) sortAfterAdd
{
    if (![_itemsToUpdate containsObject:update]) {
        [_itemsToUpdate addObject:update];
        CFDictionaryAddValue(_availableUpdates, objc_unretainedPointer(update.indexPath), objc_unretainedPointer(update));
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
    CFDictionaryRemoveValue(_availableUpdates, objc_unretainedPointer(update.indexPath));
    [_itemsToUpdate removeObject:update];
}

- (void)_sortItems
{
    [_itemsToUpdate sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:YES]]];
}

- (KKGridViewUpdate *)updateForIndexPath:(KKIndexPath *)indexPath
{   
    return objc_unretainedObject(CFDictionaryGetValue(_availableUpdates, objc_unretainedPointer(indexPath)));
}

- (BOOL)hasUpdateForIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewUpdate *update = objc_unretainedObject(CFDictionaryGetValue(_availableUpdates, objc_unretainedPointer(indexPath)));
    if (update && !update.animating)
        return YES;

    return NO;
}

- (KKIndexPath *)nextUpdateFromIndexPath:(KKIndexPath *)indexPath fallbackPath:(KKIndexPath *)fallback
{
    if (!_itemsToUpdate.count)
        return fallback;
    
    [self _sortItems];
    NSUInteger index = [_itemsToUpdate indexOfObject:[self updateForIndexPath:indexPath]];
    if ([_itemsToUpdate count] > (index + 1)) {
        KKGridViewUpdate *update = [_itemsToUpdate objectAtIndex:index + 1];
        return update.indexPath;
    }
    
    return fallback;
}

@end
