//
//  KKIndexPath.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KKIndexPath : NSObject {
    NSUInteger _section;
    NSUInteger _index;
}

- (id)initWithIndex:(NSUInteger)index section:(NSUInteger)section;
+ (id)indexPathForIndex:(NSUInteger)index inSection:(NSUInteger)section;

@property (nonatomic, readwrite) NSUInteger section;
@property (nonatomic, readwrite) NSUInteger index;

@end
