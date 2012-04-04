//
//  KKIndexPath.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

@interface KKIndexPath : NSObject <NSCopying>
+ (KKIndexPath *)zeroIndexPath;
+ (NSArray *)indexPathsWithNSIndexPaths:(NSArray *)indexPaths;

- (id)initWithIndex:(NSUInteger)index section:(NSUInteger)section;
+ (id)indexPathForIndex:(NSUInteger)index inSection:(NSUInteger)section;

- (id)initWithNSIndexPath:(NSIndexPath *)indexPath;
+ (id)indexPathWithNSIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)NSIndexPath;

- (NSComparisonResult)compare:(id)other;

@property (nonatomic, readwrite) NSUInteger section;
@property (nonatomic, readwrite) NSUInteger index;

@end
