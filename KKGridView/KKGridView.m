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
        _dataSource = dataSource;
        _gridDelegate = delegate;
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
    
}

- (CGRect)rectForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectZero;
}

- (void)reloadContentSize
{
    __block CGSize newContentSize = CGSizeMake(self.bounds.size.width, (_cellSize.height + _cellPadding.height) + (2.f * _cellPadding.height));
    
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        newContentSize.height += [_dataSource gridView:self heightForHeaderInSection:idx];
        newContentSize.height += [_dataSource gridView:self heightForHeaderInSection:idx];
        newContentSize.height += _gridHeaderView.bounds.size.height + _gridFooterView.bounds.size.height;
    }];
    
    [super setContentSize:newContentSize];
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

#pragma mark - General

- (void)reloadData
{
    
}

@end
