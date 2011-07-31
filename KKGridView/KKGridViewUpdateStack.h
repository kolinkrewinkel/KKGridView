//
//  KKGridViewUpdateStack.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridView.h"

@class KKGridViewUpdate;
@interface KKGridViewUpdateStack : NSObject

@property (nonatomic, readonly) NSMutableArray *itemsToUpdate;

- (BOOL)addUpdate:(KKGridViewUpdate *)update;
- (void)addUpdates:(NSArray *)updates;
- (BOOL)hasUpdateForIndexPath:(KKIndexPath *)indexPath;
- (KKGridViewUpdate *)updateForIndexPath:(KKIndexPath *)indexPath;
- (BOOL)removeUpdateForIndexPath:(KKIndexPath *)indexPath;

@end
