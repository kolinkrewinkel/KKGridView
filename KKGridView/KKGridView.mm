//
//  KKGridView.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridView.h"
#import "KKGridViewHeader.h"
#import "KKIndexPath.h"
#import "KKGridViewUpdate.h"
#import "KKGridViewUpdateStack.h"
#import "KKGridViewCell.h"
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
    NSMutableArray *_headerViews;
    NSArray *_lastVisibleIndexPaths;
    BOOL _markedForDisplay;
    NSUInteger _numberOfItems;
    dispatch_queue_t _renderQueue;
    NSMutableDictionary *_reusableCells;
    
    std::vector<CGFloat> _sectionHeights;
    std::vector<NSUInteger> _sectionItemCount;
    NSMutableDictionary *_visibleCells;
    NSRange _visibleSections;
    NSMutableSet *_selectedIndexPaths;
    //    BOOL _modifyingItems;
    BOOL _staggerForInsertion;
    KKGridViewUpdateStack *_updateStack;
}

- (void)_sharedInitialization;
- (void)_layoutGridView;
- (void)_reloadIntegers;
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;
- (void)_respondToBoundsChange;

@end

@implementation KKGridView

@synthesize allowsMultipleSelection = _allowsMultipleSelection;
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
    dispatch_release(_renderQueue), _renderQueue = nil;
#ifndef KK_ARC_ON
    [_reusableCells release], _reusableCells = nil;
    [_visibleCells release], _visibleCells = nil;
    [super dealloc];
#endif
}

#pragma mark - Initialization Methods

- (void)_sharedInitialization
{
    _reusableCells = [[NSMutableDictionary alloc] init];
    _visibleCells = [[NSMutableDictionary alloc] init];
    _selectedIndexPaths = [[NSMutableSet alloc] init];
    _updateStack = [[KKGridViewUpdateStack alloc] init];
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
    [self reloadData];
    [self _layoutGridView];
}

- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    [super setFrame:frame];
    if (_renderQueue != NULL && !CGSizeEqualToSize(frame.size, oldFrame.size)) {
        [self _respondToBoundsChange];
    }
}

- (void)setBounds:(CGRect)bounds
{
    CGRect oldBounds = self.bounds;
    [super setBounds:bounds];
    if (_renderQueue != NULL && !CGSizeEqualToSize(bounds.size, oldBounds.size)) {
        [self _respondToBoundsChange];
    }
}


- (KKIndexPath *)indexPathForCell:(KKGridViewCell *)cell
{
    for (KKIndexPath *indexPath in [_visibleCells allKeys]) {
        if ([_visibleCells objectForKey:indexPath] == cell)
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

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    NSMutableArray *updates = [NSMutableArray array];
    
    for (KKIndexPath *indexPath in indexPaths) {
        [updates addObject:[KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemInsert animation:animation]];
    }
    
    [_updateStack addUpdates:updates];
    [self _layoutGridView];
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

- (void)_incrementVisibleCellsByAmount:(NSUInteger)amount fromIndexPath:(KKIndexPath *)fromPath throughIndexPath:(KKIndexPath *)throughPath
{
    NSArray *keys = [_visibleCells allKeys];
    NSArray *values = [_visibleCells allValues];
    
    NSMutableDictionary *newVisibleCells = [NSMutableDictionary dictionary];
    
    
    NSUInteger index = 0;
    for (KKIndexPath *indexPath in keys) {
        if ([indexPath compare:fromPath] == (NSOrderedSame | NSOrderedAscending) && [indexPath compare:throughPath] == (NSOrderedSame | NSOrderedDescending)) {
            //KKIndexPath *newPath = [indexPath copy];
            //newPath.index++;
            [newVisibleCells setObject:[values objectAtIndex:index] forKey:indexPath];
            index++;
        }
        
    }
    
    [_visibleCells removeAllObjects];
    [_visibleCells addEntriesFromDictionary:newVisibleCells];
}

- (void)_layoutGridView
{
    // TODO: add an update method so cells can be updated by datasource
    dispatch_sync(_renderQueue, ^(void) {
        const CGRect visibleBounds = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
        NSArray *visiblePaths = [self visibleIndexPaths];
        
        //        From CHGridView; thanks Cameron (even though I didn't ask you)
        CGFloat offset = self.contentOffset.y;
        
        for (KKGridViewHeader *header in _headerViews) {
            CGRect f = [header.view frame];
            f.size.width = visibleBounds.size.width;
            CGFloat sectionY = header->stickPoint;
            
            if(sectionY <= offset && offset > 0.0f) {
                f.origin.y = offset;
                if(offset <= 0.0f) f.origin.y = sectionY;
                
                KKGridViewHeader *sectionTwo = [_headerViews count] > header->section + 1 ? [_headerViews objectAtIndex:header->section + 1] : nil;
                if (sectionTwo != nil) {
                    CGFloat sectionTwoHeight = sectionTwo.view.frame.size.height;
                    CGFloat sectionTwoY = sectionTwo->stickPoint;
                    if((offset + sectionTwoHeight) >= sectionTwoY) {
                        f.origin.y = sectionTwoY - sectionTwoHeight;
                    }
                }
            } else {
                f.origin.y = header->stickPoint;
            }
            
            header.view.frame = f;
        }
        
        for (KKIndexPath *indexPath in visiblePaths) {
            if ([_updateStack hasUpdateForIndexPath:indexPath]) {
                
                KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
                if (update.type == KKGridViewUpdateTypeItemInsert) {
                    [self _incrementVisibleCellsByAmount:1 fromIndexPath:indexPath throughIndexPath:[visiblePaths lastObject]];
                }
                _markedForDisplay = YES;
                KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
                cell.selected = [_selectedIndexPaths containsObject:indexPath];
                if (!cell) {
                    cell = [_dataSource gridView:self cellForRowAtIndexPath:indexPath];
                    [_visibleCells setObject:cell forKey:indexPath];
                    cell.frame = [self rectForCellAtIndexPath:indexPath];
                    
                    switch (update.animation) {
                        case KKGridViewAnimationExplode: {
                            cell.alpha = 0.f;
                            cell.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
                            cell.backgroundColor = [UIColor greenColor];
                            [self addSubview:cell];
                            [self bringSubviewToFront:cell];
                            [UIView animateWithDuration:0.15 animations:^(void) {
                                cell.alpha = 0.8f;
                                cell.transform = CGAffineTransformMakeScale(1.1f, 1.f);
                            } completion:^(BOOL finished) {
                                [UIView animateWithDuration:0.05 animations:^(void) {
                                    cell.alpha = 0.75f;
                                    cell.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
                                } completion:^(BOOL finished) {
                                    [UIView animateWithDuration:0.05 animations:^(void) {
                                        cell.alpha = 1.f;
                                        cell.transform = CGAffineTransformIdentity;

                                    }];
                                }];
                            }];
                            break;
                        }   
                            
                        default:
                            break;
                    }
                    
                }
                
                [_updateStack removeUpdateForIndexPath:indexPath];
            } else {
                //            TODO: ALWAYS CALL DELEGATE METHOD BY RETURNING VISIBLE CELL IN DEQUEUE METHOD
                KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
                cell.selected = [_selectedIndexPaths containsObject:indexPath];
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
        
        _markedForDisplay = NO;
        _staggerForInsertion = NO;
    });
}

- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier
{
#ifndef KK_ARC_ON
    [cell retain];
#endif
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
        numberOfRows = ceilf(_sectionItemCount[section] / [[NSNumber numberWithUnsignedInt:_numberOfColumns] floatValue]);
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

- (NSMutableArray *)visibleIndexPaths
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

- (NSArray *)indexPathsForItemsInRect:(CGRect)rect
{
    NSArray *visiblePaths = [self visibleIndexPaths];
    NSMutableArray *indexes = [[[NSMutableArray alloc] init] autorelease];
    
    for (KKIndexPath *indexPath in visiblePaths) {
        CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, cellRect)) {
            [indexes addObject:indexPath];
        }
    }
    
    return indexes;
}

- (KKIndexPath *)indexPathsForItemAtPoint:(CGPoint)point
{
    NSArray *indexes = [self indexPathsForItemsInRect:CGRectMake(point.x, point.y, 1.f, 1.f)];
    return ([indexes count] > 0) ? [indexes objectAtIndex:0] : [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}


- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    if (_allowsMultipleSelection) {
        if ([_selectedIndexPaths containsObject:indexPath]) {
            [_selectedIndexPaths removeObject:indexPath];
            cell.selected = NO;
        } else {
            [_selectedIndexPaths addObject:indexPath];
            cell.selected = YES;
        }
    } else {
        if ([_selectedIndexPaths count] > 0) {
            KKGridViewCell *otherCell = [_visibleCells objectForKey:[_selectedIndexPaths anyObject]];
            otherCell.selected = NO;
            [_selectedIndexPaths removeAllObjects];
        }
        [_selectedIndexPaths addObject:indexPath];
        cell.selected = YES;
    }
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass:[KKGridViewCell class]]) {
        KKGridViewCell *cell = (KKGridViewCell *)touch.view;
        cell.selected = YES;
    }
    KKIndexPath * touchedItemPoint = [self indexPathsForItemAtPoint:[touch locationInView:self]];
    if (touchedItemPoint.index == NSNotFound) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    [self performSelector:@selector(_selectItemAtIndexPath:) withObject:touchedItemPoint];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    KKIndexPath * indexPath = [self indexPathsForItemAtPoint:location];
    if (indexPath.index == NSNotFound) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    if (_flags.delegateRespondsToDidSelectItem) {
        [_gridDelegate gridView:self didSelectItemIndexPath:indexPath];
    }
    
    [super touchesEnded:touches withEvent:event];
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    if (!allowsMultipleSelection && _allowsMultipleSelection == YES) {
        [_selectedIndexPaths removeAllObjects];
        [UIView animateWithDuration:0.25 animations:^(void) {
            [self _layoutGridView];
        }];
    }
    _allowsMultipleSelection = allowsMultipleSelection;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier 
{
    if (!identifier) return nil;
    
    NSMutableSet *reusableCellsForIdentifier = [_reusableCells objectForKey:identifier];
    
    if ([reusableCellsForIdentifier count] == 0)
        return nil;
    
    KKGridViewCell *reusableCell = [reusableCellsForIdentifier anyObject];
#ifndef KK_ARC_ON
    [[reusableCell retain] autorelease]; // HOLD IT
#endif
    [reusableCellsForIdentifier removeObject:reusableCell];
    
    [reusableCell prepareForReuse];
    
    return reusableCell;
}

#pragma mark - Setters

- (void)setCellSize:(CGSize)cellSize
{
    _cellSize = cellSize;
    if (_cellPadding.width != 0.f && _cellPadding.height != 0.f) {
        [self reloadData];
    }
}

- (void)setCellPadding:(CGSize)cellPadding
{
    _cellPadding = cellPadding;
    if (_cellSize.width != 0.f && _cellSize.height != 0.f) {
        [self reloadData];
    }
}

- (void)setDataSource:(id<KKGridViewDataSource>)dataSource
{
    _dataSource = dataSource;
    _flags.dataSourceRespondsToHeightForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:heightForHeaderInSection:)];
    _flags.dataSourceRespondsToHeightForFooterInSection = [_dataSource respondsToSelector:@selector(gridView:heightForFooterInSection:)];
    _flags.dataSourceRespondsToNumberOfSections = [_dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)];
    _flags.dataSourceRespondsToViewForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:viewForHeaderInSection:)];
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
        if (_headerViews) {
            [[_headerViews valueForKey:@"view"] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_headerViews removeAllObjects];
        }
        
        if (!_headerViews) {
            _headerViews = [[NSMutableArray alloc] initWithCapacity:_numberOfSections];
        }
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            UIView *view = [_dataSource gridView:self viewForHeaderInSection:section];
            KKGridViewHeader *header = [[KKGridViewHeader alloc] initWithView:view];
            [_headerViews addObject:header];
            [header release];
            
            CGFloat headerHeight = _headerHeights[section];
            CGFloat position = [self sectionHeightsCombinedUpToSection:section];
            header.view.frame = CGRectMake(0.f, position, self.bounds.size.width, headerHeight);
            header->stickPoint = position;
            header->section = section;
            [self addSubview:header.view];
        }
    }
    
    for (KKGridViewCell *cell in [_visibleCells allValues]) {
        NSMutableSet *set = [_reusableCells objectForKey:cell.reuseIdentifier];
        [set addObject:cell];
    }
    [[_visibleCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [_visibleCells removeAllObjects];
}

- (void)softReload
{
    [self reloadContentSize];
    
    if (_flags.dataSourceRespondsToViewForHeaderInSection) {
        if (_headerViews) {
            [[_headerViews valueForKey:@"view"] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_headerViews removeAllObjects];
        }
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            if (!_headerViews) {
                _headerViews = [[NSMutableArray alloc] init];
            }
            
            UIView *view = [_dataSource gridView:self viewForHeaderInSection:section];
            KKGridViewHeader *header = [[KKGridViewHeader alloc] initWithView:view];
            [_headerViews addObject:header];
            [header release];
            
            CGFloat headerHeight = _headerHeights[section];
            CGFloat position = [self sectionHeightsCombinedUpToSection:section];
            header.view.frame = CGRectMake(0.f, position, self.bounds.size.width, headerHeight);
            header->stickPoint = position;
            header->section = section;
            [self addSubview:header.view];
        }
    }
    
    //    for (KKGridViewCell *cell in [_visibleCells allValues]) {
    //        NSMutableSet *set = [_reusableCells objectForKey:cell.reuseIdentifier];
    //        [set addObject:cell];
    //    }
    //    [[_visibleCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //    
    //    [_visibleCells removeAllObjects];
}

@end
