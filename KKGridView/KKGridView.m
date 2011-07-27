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
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;
- (BOOL)_headerViewForSectionShouldBeFixed:(NSUInteger)section;

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

#pragma mark - NSObject

- (void)dealloc
{
    [_reusableCells release], _reusableCells = nil;
    [_visibleCells release], _visibleCells = nil;
    dispatch_release(_renderQueue), _renderQueue = nil;
    _dataSource = nil;
    _gridDelegate = nil;
    [super dealloc];
}

#pragma mark - Initialization Methods

- (void)_sharedInitialization
{
    _reusableCells = [[NSMutableDictionary alloc] init];
    _visibleCells = [[NSMutableDictionary alloc] init];
    _renderQueue = dispatch_queue_create("com.gridviewdemo.kkgridview", NULL);
    dispatch_queue_t high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_set_target_queue(_renderQueue, high);
    
    self.alwaysBounceVertical = YES;
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
    [self _layoutGridView];
    [super layoutSubviews];
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

- (CGFloat)sectionHeightsCombinedUpToSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    for (NSUInteger index = 0; index < section; index++) {
        NSNumber *number = (NSNumber *)CFArrayGetValueAtIndex((CFArrayRef)_sectionHeights, index);
        height += [number floatValue];
        height += _cellPadding.height;

    }
    height -= [(NSNumber *)CFDictionaryGetValue((CFDictionaryRef)_headerHeights, [NSNumber numberWithUnsignedInt:section]) floatValue];
    return height;
}

- (CGRect)_CGRectFromVerticalOffset:(CGFloat)offset height:(CGFloat)height
{
    return CGRectMake(0,offset,self.bounds.size.width,height);
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    return [self _CGRectFromVerticalOffset:[self sectionHeightsCombinedUpToSection:section] height:[(NSNumber *)CFDictionaryGetValue((CFDictionaryRef)_headerHeights, [NSNumber numberWithUnsignedInt:section]) floatValue]];
}

- (void)_layoutGridView
{
    // add an update method so cells can be updated by datasource
    dispatch_sync(_renderQueue, ^(void) {
        const CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);

        NSArray *visiblePaths = [self visibleIndexPaths];
        
        NSMutableSet *sections = [NSMutableSet set];
        
        for (KKIndexPath *indexPath in visiblePaths) {
            [sections addObject:[NSNumber numberWithUnsignedInt:indexPath.section]];
        }
                
        for (KKIndexPath *indexPath in visiblePaths) {
            UIView * header = (UIView *)CFDictionaryGetValue((CFDictionaryRef)_headerViews, [NSNumber numberWithUnsignedInt:indexPath.section]);
            CGFloat headerHeight = [(NSNumber *)CFDictionaryGetValue((CFDictionaryRef)_headerHeights, [NSNumber numberWithUnsignedInt:indexPath.section]) floatValue];
            
            CGRect lastCellRect = [self rectForCellAtIndexPath:[KKIndexPath indexPathForIndex:([[_sectionItemCount objectAtIndex:indexPath.section] unsignedIntValue] - 1) inSection:indexPath.section]];
            
            if (!header.superview) {
                header.frame = CGRectMake(0.f, [self sectionHeightsCombinedUpToSection:indexPath.section], self.bounds.size.width, headerHeight);
                [self addSubview:header];
            }
            
            
            
            
//            NSUInteger interim = CGRectGetMaxY(lastCellRect) - self.contentOffset.y;
            
            if ([[visiblePaths objectAtIndex:0] section] == indexPath.section && (self.contentOffset.y <= (CGRectGetMaxY(lastCellRect)) - headerHeight)) {
                header.frame = CGRectMake(0.f, MAX(self.contentOffset.y, 0.f), self.bounds.size.width, headerHeight);
//            } else if (interim <= headerHeight && interim > 0) {
//                header.backgroundColor = [UIColor redColor];
            } else {
            }

        }

        if ([visiblePaths isEqualToArray:_lastVisibleIndexPaths]) {
            _lastVisibleIndexPaths = [visiblePaths retain];
            return;
        }
        _lastVisibleIndexPaths = [visiblePaths retain];
        
        
        
        for (KKIndexPath *indexPath in visiblePaths) {

            
            
            KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
            if (!cell) {
                cell = [_dataSource gridView:self cellForRowAtIndexPath:indexPath];
                [_visibleCells setObject:cell forKey:indexPath];
                cell.frame = [self rectForCellAtIndexPath:indexPath];
                [self addSubview:cell];
                [self sendSubviewToBack:cell];
            }
            
        }
        
        NSArray *visible = [_visibleCells allValues];
        NSArray *keys = [_visibleCells allKeys];
        NSUInteger loopCount = 0;
        for (KKGridViewCell *cell in visible) {
            if (!KKCGRectIntersectsRectVertically(cell.frame, visibleBounds)) {
                [cell removeFromSuperview];
                [_visibleCells removeObjectForKey:[keys objectAtIndex:loopCount]];
                [self _enqueueCell:cell withIdentifier:cell.reuseIdentifier];
            }
            loopCount++;
        }
        
        NSArray *headerKeys = [_headerViews allKeys];
 
        NSUInteger indexl = 0;
        for (UIView *view in [_headerViews allValues]) {

            if (![sections containsObject:[headerKeys objectAtIndex:indexl]]) {
                [view removeFromSuperview];
            }
            
            indexl++;

        }
        
    });
}

- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier
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
    
    if (_headerHeights && [_headerHeights count] > 0) {
        height += [(id)CFDictionaryGetValue((CFDictionaryRef)_headerHeights, [NSNumber numberWithUnsignedInt:section]) floatValue];
        
    } else {
        height += KKGridViewDefaultHeaderHeight;
    }
    
    if (_footerHeights && [_footerHeights count] > 0) {
//        height += [(id)CFDictionaryGetValue((CFDictionaryRef)_footerHeights, [NSNumber numberWithUnsignedInt:section]) floatValue];
    }    
    
    CGFloat numberOfRows = 0.f;
    
    if (_sectionItemCount) {
        numberOfRows = (ceilf([(id)CFArrayGetValueAtIndex((CFArrayRef)_sectionItemCount, section) unsignedIntValue] / (CGFloat)_numberOfColumns));
    } else {
        numberOfRows = (ceilf([_dataSource gridView:self numberOfItemsInSection:section] / (CGFloat)_numberOfColumns));
    }
    
    height += numberOfRows * (_cellSize.height + _cellPadding.height);
    return height;
}

- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath
{
    CGRect rect = CGRectZero;
    CGFloat yPosition = _cellPadding.height;
    CGFloat xPosition = _cellPadding.width;
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        if (_sectionHeights && [_sectionHeights count] > 0) {
            id number = (id) CFArrayGetValueAtIndex((CFArrayRef)_sectionHeights, section);
            yPosition += [number floatValue];
        } else {
            yPosition += [self heightForSection:section];
        }
    }
    
    NSInteger row = floor(indexPath.index / _numberOfColumns);
    NSInteger column = indexPath.index - (row * _numberOfColumns);
    
    yPosition += (row * (_cellSize.height + _cellPadding.height));
    xPosition += (column * (_cellSize.width + _cellPadding.width));
    
    rect.size = _cellSize;
    rect.origin.y = yPosition;
    rect.origin.x = xPosition;
    
    return rect;
}

- (NSArray *)visibleIndexPaths
{
    const CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
    NSMutableArray *indexPaths = [[[NSMutableArray alloc] init] autorelease];
    
    KKIndexPath *indexPath = [KKIndexPath indexPathForIndex:0 inSection:0];
    
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        for (NSUInteger index = 0; index < [_dataSource gridView:self numberOfItemsInSection:section]; index++) {
            
            indexPath.section = section;
            indexPath.index = index;
            
            CGRect rect = [self rectForCellAtIndexPath:indexPath];
            if (KKCGRectIntersectsRectVertically(rect, visibleBounds)) {
                [indexPaths addObject:[[indexPath copy] autorelease]];
            } else if (CGRectGetMinY(rect) > CGRectGetMaxY(visibleBounds)) {
                break;
            }
        }
    }
    
    //    if ([indexPaths count] > 0) {
    //        _visibleSections.location = [[indexPaths objectAtIndex:0] section];
    //        _visibleSections.length = [[indexPaths lastObject] section] - MAX(_visibleSections.location - 1, 0);
    //    }
    
    return indexPaths;
}

- (void)reloadContentSize
{
    [self _reloadIntegers];
    
    _numberOfColumns = [[NSString stringWithFormat:@"%f", self.bounds.size.width / (_cellSize.width + _cellPadding.width)] integerValue];
    
    __block CGSize newContentSize = CGSizeMake(self.bounds.size.width, 0.f);
    
    if (!_sectionHeights) {
        _sectionHeights = [[NSMutableArray alloc] init];
    }
    [_sectionHeights removeAllObjects];
    
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CGFloat heightForSection = [self heightForSection:idx];
        [_sectionHeights addObject:[NSNumber numberWithFloat:heightForSection]];
        newContentSize.height += heightForSection;
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
    
    [_headerHeights removeAllObjects];
    if (_flags.dataSourceRespondsToHeightForHeaderInSection) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            if (!_headerHeights) {
                _headerHeights = [[NSMutableDictionary alloc] init];
            }
            [_headerHeights setObject:[NSNumber numberWithFloat:[_dataSource gridView:self heightForHeaderInSection:section]] forKey:[NSNumber numberWithUnsignedInt:section]];
        }
    }
    
    [_sectionItemCount removeAllObjects];
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        if (!_sectionItemCount) {
            _sectionItemCount = [[NSMutableArray alloc] init];
        }
        [_sectionItemCount addObject:[NSNumber numberWithUnsignedInt:[_dataSource gridView:self numberOfItemsInSection:section]]];
    }
    
    
}

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier 
{
    if (!identifier) return nil;
    
    NSMutableSet *reuseableCellsForIdentifier = [_reusableCells objectForKey:identifier]; 
    
    if ([reuseableCellsForIdentifier count] == 0) {
        [_reusableCells setObject:[NSMutableSet set] forKey:identifier];
        return nil;
    }
    
    KKGridViewCell *reusableCell = [reuseableCellsForIdentifier anyObject];
    [[reusableCell retain] autorelease]; // HOLD IT
    [reuseableCellsForIdentifier removeObject:reusableCell];
    
    [reusableCell prepareForReuse];
    
    return reusableCell;
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
    _flags.dataSourceRespondsToViewForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:viewForHeaderInSection:)];
    
    [self reloadData];
}

- (void)setGridDelegate:(id<KKGridViewDelegate>)gridDelegate
{
    _gridDelegate = gridDelegate;
    _flags.delegateRespondsToDidSelectItem = [_gridDelegate respondsToSelector:@selector(gridView:didSelectItemIndexPath:)];
}

- (BOOL)_headerViewForSectionShouldBeFixed:(NSUInteger)section
{
    
    const CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
    
    CGRect acceptableSectionBoundaries = CGRectMake(0.f, [self sectionHeightsCombinedUpToSection:section], self.bounds.size.width, [(NSNumber *)CFArrayGetValueAtIndex((CFArrayRef)_sectionHeights, section) floatValue]);
    return (KKCGRectIntersectsRectVertically(acceptableSectionBoundaries, visibleBounds));
}

#pragma mark - General

- (void)reloadData
{
    [self _reloadIntegers];
    if (_flags.dataSourceRespondsToViewForHeaderInSection) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            if (!_headerViews) {
                _headerViews = [[NSMutableDictionary alloc] init];
            }
            
            [_headerViews setObject:[_dataSource gridView:self viewForHeaderInSection:section] forKey:[NSNumber numberWithUnsignedInt:section]];
        }
    }
}

@end
