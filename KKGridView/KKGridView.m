//
//  KKGridView.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridView.h"

@interface KKGridView ()

- (void)_sharedInitialization;
- (void)_layoutGridView;
- (void)_reloadIntegers;

@end

@implementation KKGridView

@synthesize cellPadding = _cellPadding;
@synthesize cellSize = _cellSize;
@synthesize dataSource = _dataSource;
@synthesize gridDelegate = _gridDelegate;
@synthesize gridFooterView = _gridFooterView;
@synthesize gridHeaderView = _gridHeaderView;
@synthesize numberOfColumns = _numberOfColumns;
@synthesize numberOfSections = _numberOfSections;

#pragma mark - Initialization Methods

- (void)_sharedInitialization
{
    _reusableCells = [[NSMutableDictionary alloc] init];
    _visibleCells = [[NSMutableDictionary alloc] init];
}

- (id)init
{
    if ((self = [super init])) {
        [self _sharedInitialization];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self _sharedInitialization];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self _sharedInitialization];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame dataSource:(id<KKGridViewDataSource>)dataSource delegate:(id<KKGridViewDelegate>)delegate
{
    if ((self = [self initWithFrame:frame])) {
        self.dataSource = dataSource;
        self.gridDelegate = delegate;
    }
    
    return self;
}

#pragma mark - Metrics + Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self _layoutGridView];
}

- (KKIndexPath *)indexPathForCell:(KKGridViewCell *)cell
{
    for (KKIndexPath *indexPath in [_visibleCells allKeys]) {
        if ([_visibleCells objectForKey:indexPath] == cell) {
            return indexPath;
        }
    }
    return [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

- (void)_layoutGridView
{
    CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
    
    for (KKIndexPath *indexPath in [self visibleIndexPaths]) {
        KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];

        if (cell) {
            cell.frame = [self rectForCellAtIndexPath:indexPath];

        } else {
            cell = [_dataSource gridView:self cellForRowAtIndexPath:indexPath];
            [_visibleCells setObject:[cell retain] forKey:indexPath];
            NSLog(@"%@", [_visibleCells objectForKey:indexPath]);
            cell.frame = [self rectForCellAtIndexPath:indexPath];

            if (!cell.superview)
                [self addSubview:cell];
        }
        
    }
    for (KKGridViewCell *cell in [_visibleCells allValues]) {
        KKIndexPath *indexPath = [self indexPathForCell:cell];
        if (!CGRectIntersectsRect(visibleBounds, cell.frame)) {
            [cell removeFromSuperview];
            [_visibleCells removeObjectForKey:indexPath];
            [self enqueueCell:cell withIdentifier:cell.reuseIdentifier];
        }
    }
}

- (void)enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier
{
    NSMutableSet *set = [_reusableCells objectForKey:identifier];
    if (!set) {
        [_reusableCells setObject:[NSMutableSet set] forKey:identifier];
        set = [_reusableCells objectForKey:identifier];
    }
    
    [set addObject:cell];
}

- (CGFloat)heightForSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    
    if (_flags.dataSourceRespondsToHeightForHeaderInSection) {
        height += [_dataSource gridView:self heightForHeaderInSection:section];
    } else {
        height += 27.f;
    }
    
    if (_flags.dataSourceRespondsToHeightForFooterInSection)
        height += [_dataSource gridView:self heightForFooterInSection:section];
    
    height += (ceilf([_dataSource gridView:self numberOfItemsInSection:section] / (CGFloat)_numberOfColumns)) * (_cellSize.height + _cellPadding.height);
    return height;
}

- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath
{
    CGRect rect = CGRectZero;
    CGFloat yPosition = _cellPadding.height;
    CGFloat xPosition = _cellPadding.width;
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        yPosition += [self heightForSection:section];
    }

    NSUInteger numberOfColumns = floor(self.bounds.size.height / ((_cellSize.width + _cellPadding.width) + (2.f * _cellPadding.width)));
    NSInteger row = floor(indexPath.index / numberOfColumns);
    NSInteger column = indexPath.index - (row * numberOfColumns);
    
    yPosition += (row * (_cellSize.height + _cellPadding.height));
    xPosition += (column * (_cellSize.width + _cellPadding.width));

    rect.size = _cellSize;
    rect.origin.y = yPosition;
    rect.origin.x = xPosition;
    
    return rect;
}

- (NSArray *)visibleIndexPaths
{
    NSMutableArray *visiblePaths = [[NSMutableArray alloc] init];
    CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
    
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        
        for (NSUInteger index = 0; index < [_dataSource gridView:self numberOfItemsInSection:section]; index++) {
            KKIndexPath *indexPath = [[KKIndexPath indexPathForIndex:index inSection:section] retain];
            CGRect rect = [self rectForCellAtIndexPath:indexPath];
            if (CGRectIntersectsRect(visibleBounds, rect))
                [visiblePaths addObject:indexPath];
        
        }
        
    }
    
    return [visiblePaths autorelease];
}

- (void)reloadContentSize
{
    [self _reloadIntegers];

	NSUInteger rows = floor(self.bounds.size.height / ((_cellSize.width + _cellPadding.width) + (2.f * _cellPadding.width)));
	NSUInteger cols = _numberOfItems / rows;
    _numberOfColumns = [[NSString stringWithFormat:@"%f", self.bounds.size.width / (_cellSize.width + _cellPadding.width)] unsignedIntValue];
    
    __block CGSize newContentSize = CGSizeMake(self.bounds.size.width, (cols * (_cellSize.height + _cellPadding.height)) + (2.f * _cellPadding.height));
        
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        newContentSize.height += [self heightForSection:idx];
    }];
    
    [super setContentSize:newContentSize];
}

- (void)_reloadIntegers
{
    if (_flags.dataSourceRespondsToNumberOfSections) {
        _numberOfSections = [_dataSource numberOfSectionsInGridView:self];
    } else {
        _numberOfSections = 1;
    }
    
    NSUInteger newNumberOfItems = 0;
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        newNumberOfItems += [_dataSource gridView:self numberOfItemsInSection:section];
    }
    _numberOfItems = 0;
    _numberOfItems = newNumberOfItems;
}
            
#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    
    if (!identifier) return nil;
    
    // Get possible reuseable cells for the identifier
    NSMutableSet *reuseableCellsForIdentifier = [_reusableCells objectForKey:identifier]; 
    
    
    // None available, return nil and let the user create a new one.
    if ([reuseableCellsForIdentifier count] == 0) {
        [_reusableCells setObject:[NSMutableSet set] forKey:identifier];
        return nil;
    }
    // Get any reuseable cell.
    KKGridViewCell *reusableCell = [reuseableCellsForIdentifier anyObject];
    [reusableCell retain];
    
    // Remove it.
    [reuseableCellsForIdentifier removeObject:reusableCell];
    
    // If someone wants to handle some stuff.
    [reusableCell prepareForReuse];
    
    // Return the reused cell.
    return [reusableCell autorelease];
}

- (NSIndexSet *)visibleIndices
{
    return [NSIndexSet indexSet];
}

#pragma mark - Setters

- (void)setCellSize:(CGSize)cellSize
{
    _cellSize = cellSize;
    [self reloadContentSize];
}

- (void)setCellPadding:(CGSize)cellPadding
{
    _cellPadding = cellPadding;
    [self reloadContentSize];
}

- (void)setDataSource:(id<KKGridViewDataSource>)dataSource
{
    _dataSource = dataSource;
    _flags.dataSourceRespondsToHeightForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:heightForHeaderInSection:)];
    _flags.dataSourceRespondsToHeightForFooterInSection = [_dataSource respondsToSelector:@selector(gridView:heightForFooterInSection:)];
    _flags.dataSourceRespondsToNumberOfSections = [_dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)];
    [self reloadData];
}

- (void)setGridDelegate:(id<KKGridViewDelegate>)gridDelegate
{
    _gridDelegate = gridDelegate;
    _flags.delegateRespondsToDidSelectItem = [_gridDelegate respondsToSelector:@selector(gridView:didSelectItemIndexPath:)];
}

#pragma mark - General

- (void)reloadData
{
    [self _reloadIntegers];
}

@end
