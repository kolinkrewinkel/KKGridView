//
//  KKGridView.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridView.h"
#import <map>
#import <vector>

@interface KKGridView () {
    struct {
        unsigned dataSourceRespondsToHeightForFooterInSection:1;
        unsigned dataSourceRespondsToHeightForHeaderInSection:1;
        unsigned dataSourceRespondsToViewForHeaderInSection;
        unsigned dataSourceRespondsToNumberOfSections:1;
        unsigned delegateRespondsToDidSelectItem:1;
    } _flags;
    
    std::vector<CGFloat> _footerHeights;
    std::vector<CGFloat> _headerHeights;
    
    NSMutableArray *_footerViews;
    NSMutableDictionary *_headerViews;
    NSArray *_lastVisibleIndexPaths;
    BOOL _markedForDisplay;
    NSUInteger _numberOfItems;
    dispatch_queue_t _renderQueue;
    NSMutableDictionary *_reusableCells;
    
    std::vector<CGFloat> _sectionHeights;
    std::vector<NSUInteger> _sectionItemCount;
    NSMutableDictionary *_visibleCells;
    NSRange _visibleSections;
}

- (void)_sharedInitialization;
- (void)_layoutGridView;
- (void)_reloadIntegers;
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;
- (void)_respondToBoundsChange;

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

- (void)_respondToBoundsChange
{
    [self reloadContentSize];
    [self _layoutGridView];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self _respondToBoundsChange];
}

- (KKIndexPath *)indexPathForCell:(KKGridViewCell *)cell
{
    for (KKIndexPath *indexPath in [_visibleCells allKeys]) {
        if (CFDictionaryGetValue((CFMutableDictionaryRef)_visibleCells, indexPath) == cell)
            return indexPath;
    }
    return [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

- (CGFloat)sectionHeightsCombinedUpToSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    for (NSUInteger index = 0; index < section; index++) {
        height += _sectionHeights[index];
    }
    return height;
}

- (NSArray *)_allPotentiallyVisibleIndexPaths
{
    const CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
    NSMutableArray *indexPaths = [[[NSMutableArray alloc] init] autorelease];
    
    KKIndexPath *indexPath = [KKIndexPath indexPathForIndex:0 inSection:0];
    
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        CGFloat headerHeight = _sectionHeights[section];
        for (NSUInteger index = 0; index < [_dataSource gridView:self numberOfItemsInSection:section]; index++) {
            
            indexPath.section = section;
            indexPath.index = index;
            
            CGRect rect = [self rectForCellAtIndexPath:indexPath];
            if (KKCGRectIntersectsRectVerticallyWithPositiveNegativeMargin(rect, visibleBounds, headerHeight)) {
                [indexPaths addObject:[[indexPath copy] autorelease]];
            } else if (CGRectGetMinY(rect) > CGRectGetMaxY(visibleBounds)) {
                break;
            }
        }
    }
    
    return indexPaths;
}

- (void)_layoutGridView
{
    // add an update method so cells can be updated by datasource
    dispatch_sync(_renderQueue, ^(void) {
        const CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
        
        NSArray *visiblePaths = [self visibleIndexPaths];
        
        for (KKIndexPath *indexPath in visiblePaths) {

            UIView * header = [_headerViews objectForKey:[NSNumber numberWithUnsignedInteger:indexPath.section]];
            CGFloat headerHeight = _headerHeights[indexPath.section];
            
            KKIndexPath *lastCellIndexPath = [KKIndexPath indexPathForIndex:(_sectionItemCount[indexPath.section] - 1)
                                                                  inSection:indexPath.section];
            CGRect lastCellRect = [self rectForCellAtIndexPath:lastCellIndexPath];
            
            if ([[visiblePaths objectAtIndex:0] section] == indexPath.section && (self.contentOffset.y <= ((CGRectGetMaxY(lastCellRect)) - headerHeight) + _cellPadding.height)) {
                header.frame = CGRectMake(0.f, MAX(self.contentOffset.y, 0.f), self.bounds.size.width, headerHeight);
            } else if (_markedForDisplay) {
                header.frame = CGRectMake(0.f, [self sectionHeightsCombinedUpToSection:indexPath.section], self.bounds.size.width, headerHeight);
            }
            
            KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
            if (!cell) {
                cell = [_dataSource gridView:self cellForRowAtIndexPath:indexPath];
                [_visibleCells setObject:cell forKey:indexPath];
                cell.frame = [self rectForCellAtIndexPath:indexPath];
                
                [self addSubview:cell];
                [self sendSubviewToBack:cell];
            } else if (_markedForDisplay) {
                cell.frame = [self rectForCellAtIndexPath:indexPath];
            }
        }
        
//        Not sure on this
        
//        if ([visiblePaths isEqualToArray:_lastVisibleIndexPaths]) {
//            _lastVisibleIndexPaths = [visiblePaths retain];
//            return;
//        }
//        _lastVisibleIndexPaths = [visiblePaths retain];
        
        NSArray *visible = [_visibleCells allValues];
        NSArray *keys = [_visibleCells allKeys];

        NSUInteger loopCount = 0;
        for (KKGridViewCell *cell in visible) {
            if (!KKCGRectIntersectsRectVertically(cell.frame, visibleBounds)) {
                [cell removeFromSuperview];
                [_visibleCells removeObjectForKey:[keys objectAtIndex:loopCount]];
//                CFDictionaryRemoveValue((CFMutableDictionaryRef)_visibleCells, CFArrayGetValueAtIndex((CFArrayRef)keys, loopCount));
                [self _enqueueCell:cell withIdentifier:cell.reuseIdentifier];
            }
            loopCount++;
        }

        _markedForDisplay = NO;

    });
}

- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier
{
    [cell retain];
    NSMutableSet *set = (NSMutableSet *)CFDictionaryGetValue((CFMutableDictionaryRef)_reusableCells, identifier);
    if (!set) {
        CFDictionarySetValue((CFMutableDictionaryRef)_reusableCells, identifier, [NSMutableSet set]);
    set = (NSMutableSet *)CFDictionaryGetValue((CFMutableDictionaryRef)_reusableCells, identifier);
    }
    CFSetAddValue((CFMutableSetRef)set, cell);
    [cell release];
}

- (CGFloat)heightForSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    
    if (_headerHeights.size() > section) {
        height += _headerHeights[section];
        
    } else {
        height += KKGridViewDefaultHeaderHeight;
    }
    
    if (_footerHeights.size() > section) {
        height += _footerHeights[section];
    }    
    
    CGFloat numberOfRows = 0.f;
    
    if (_sectionItemCount.size() > 0) {
                numberOfRows = ceilf(_sectionItemCount[section] / (CGFloat)_numberOfColumns);
    } else {
        numberOfRows = ceilf([_dataSource gridView:self numberOfItemsInSection:section] / (CGFloat)_numberOfColumns);
    }
    
    height += numberOfRows * (_cellSize.height + _cellPadding.height);
    height += _cellPadding.height;
    
    return height;
}

- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath
{
    CGRect rect = CGRectZero;
    CGFloat yPosition = _cellPadding.height;
    CGFloat xPosition = _cellPadding.width;
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        if (_sectionHeights.size() > 0) {
            yPosition += _sectionHeights[section];
        } else {
            yPosition += [self heightForSection:section];
        }
    }
    
    yPosition += _headerHeights[indexPath.section];
    
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
    
    return indexPaths;
}

- (void)reloadContentSize
{
    [self _reloadIntegers];
    
    NSUInteger oldColumns = _numberOfColumns;
    _numberOfColumns = [[NSString stringWithFormat:@"%f", self.bounds.size.width / (_cellSize.width + _cellPadding.width)] integerValue];
    
    if (oldColumns != _numberOfColumns) {
        _markedForDisplay = YES;
    }
    
    __block CGSize newContentSize = CGSizeMake(self.bounds.size.width, 0.f);
    
    _sectionHeights.clear();
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CGFloat heightForSection = [self heightForSection:idx];
        _sectionHeights.push_back(heightForSection);
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
    
    _headerHeights.clear();
    
    if (_flags.dataSourceRespondsToHeightForHeaderInSection) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            _headerHeights.push_back([_dataSource gridView:self heightForHeaderInSection:section]);
        }
    }
    
    _sectionItemCount.clear();
    
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        _sectionItemCount.push_back([_dataSource gridView:self numberOfItemsInSection:section]);
    }
}

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier 
{
    if (!identifier) return nil;
    
    NSMutableSet *reusableCellsForIdentifier = (id)CFDictionaryGetValue((CFMutableDictionaryRef)_reusableCells, identifier);
    
    if ([reusableCellsForIdentifier count] == 0)
        return nil;
    
    KKGridViewCell *reusableCell = [reusableCellsForIdentifier anyObject];
    [[reusableCell retain] autorelease]; // HOLD IT
    [reusableCellsForIdentifier removeObject:reusableCell];
    
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

#pragma mark - General

- (void)reloadData
{
    [self reloadContentSize];
    
    
    
    if (_flags.dataSourceRespondsToViewForHeaderInSection) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            if (_headerViews) {
                [[_headerViews allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [_headerViews removeAllObjects];
            }
            if (!_headerViews) {
                _headerViews = [[NSMutableDictionary alloc] init];
            }
            UIView *header = [_dataSource gridView:self viewForHeaderInSection:section];
            CFDictionarySetValue((CFMutableDictionaryRef)_headerViews, [NSNumber numberWithUnsignedInteger:section], header);

            CGFloat headerHeight = _headerHeights[section];
            
            header.frame = CGRectMake(0.f, [self sectionHeightsCombinedUpToSection:section], self.bounds.size.width, headerHeight);
            NSLog(@"%@", NSStringFromCGRect(header.frame));
            [self addSubview:header];
            [self sendSubviewToBack:header];
        }
    }
}

@end
