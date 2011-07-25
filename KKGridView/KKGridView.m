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

@property (nonatomic) BOOL _alreadyAddedViews;

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
@synthesize _alreadyAddedViews;

#pragma mark - Initialization Methods

- (void)_sharedInitialization
{
    _reusableCells = [[NSMutableSet alloc] init];
    _visibleCells = [[NSMutableSet alloc] init];
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

- (void)_layoutGridView
{
    if (!_alreadyAddedViews) {
        for (NSUInteger i = 0; i < _numberOfItems; i++) {
    //        Comment this out to avoid roasting your lap
            UIView *view = [[[UIView alloc] initWithFrame:[self rectForCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]]] autorelease];
            view.backgroundColor = [UIColor redColor];
            [self addSubview:view];
        }
    }
    _alreadyAddedViews = YES;
}

- (CGRect)rectForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = (indexPath.row + 1) * (indexPath.section + 1);
    index -= 1;
    if (index < _numberOfItems) {
        NSUInteger numberOfColumns = floor(self.bounds.size.height / ((_cellSize.width + _cellPadding.width) + (2.f * _cellPadding.width)));
        NSInteger row = floor(index / numberOfColumns);
        NSInteger column = index - (row * numberOfColumns);
        return CGRectMake((column * (_cellSize.width + _cellPadding.width)) + _cellPadding.width, (row * (_cellSize.height + _cellPadding.height)) + _cellPadding.height, _cellSize.width, _cellSize.height);
    }
    
    return CGRectZero;
}

- (void)reloadContentSize
{
    [self _reloadIntegers];

	NSUInteger rows = floor(self.bounds.size.height / ((_cellSize.width + _cellPadding.width) + (2.f * _cellPadding.width)));
	NSUInteger cols = _numberOfItems / rows;
    
    __block CGSize newContentSize = CGSizeMake(self.bounds.size.width, (cols * (_cellSize.height + _cellPadding.height)) + (2.f * _cellPadding.height));
        
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (_flags.dataSourceRespondsToHeightForFooterInSection)
            newContentSize.height += [_dataSource gridView:self heightForFooterInSection:idx];
        if (_flags.dataSourceRespondsToHeightForHeaderInSection)
            newContentSize.height += [_dataSource gridView:self heightForHeaderInSection:idx];
        newContentSize.height += _gridHeaderView.bounds.size.height + _gridFooterView.bounds.size.height;
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

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    KKGridViewCell *cell = [_reusableCells anyObject];
    if ([cell.reuseIdentifier isEqualToString:identifier]) {
        [cell retain];
        [_reusableCells removeObject:cell];
        [cell prepareForReuse];
        return [cell autorelease];
    }
    
    return nil;
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
