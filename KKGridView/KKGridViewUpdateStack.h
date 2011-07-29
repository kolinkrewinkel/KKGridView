//
//  KKGridViewUpdateStack.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewUpdate.h"

@interface KKGridViewUpdateStack : NSObject

@property (nonatomic, readonly) NSMutableArray *itemsToUpdate;

- (BOOL)addUpdate:(KKGridViewUpdate *)update;

@end
