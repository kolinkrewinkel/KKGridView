//
//  NSMutableDictionary+KKDebug.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 9.7.11.
//  Copyright (c) 2011 kxk design. All rights reserved.
//

#import "NSMutableDictionary+KKDebug.h"
#import "KKIndexPath.h"

@implementation NSMutableDictionary (KKDebug)

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if ([aKey isEqual:[KKIndexPath indexPathForIndex:1 inSection:0]]) {
        NSLog(@"%@", anObject);
    }
}

@end
