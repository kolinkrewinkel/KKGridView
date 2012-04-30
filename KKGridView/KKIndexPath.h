//
//  KKIndexPath.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

@interface KKIndexPath : NSObject <NSCopying>

#pragma mark - Initializers

- (id)initWithIndex:(NSUInteger)index section:(NSUInteger)section;
+ (id)indexPathForIndex:(NSUInteger)index inSection:(NSUInteger)section;

#pragma mark - NSIndexPath

+ (NSArray *)indexPathsWithNSIndexPaths:(NSArray *)indexPaths;
- (id)initWithNSIndexPath:(NSIndexPath *)indexPath;
+ (id)indexPathWithNSIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)NSIndexPath;

#pragma mark - NSComparisonResult

- (NSComparisonResult)compare:(id)other;

#pragma mark - Convenience

+ (KKIndexPath *)nonexistantIndexPath;
+ (KKIndexPath *)zeroIndexPath;

#pragma mark - Properties

@property (nonatomic, readwrite) NSUInteger section;
@property (nonatomic, readwrite) NSUInteger index;

@end
