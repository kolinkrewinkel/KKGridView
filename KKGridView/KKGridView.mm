//
//  KKGridView.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridView.h"
#import "KKGridViewViewInfo.h"
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
        unsigned dataSourceRespondsToViewForFooterInSection;
        unsigned dataSourceRespondsToNumberOfSections:1;
        unsigned delegateRespondsToWillSelectItem:1;
        unsigned delegateRespondsToDidSelectItem:1;
        unsigned delegateRespondsToWillDeselectItem:1;
        unsigned delegateRespondsToDidDeselectItem:1;
        unsigned delegateRespondsToWillDisplayCell:1;
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
    KKGridViewCell * _lastSelectedCell;
    //    BOOL _modifyingItems;
    BOOL _staggerForInsertion;
    __strong KKGridViewUpdateStack *_updateStack;
}

- (void)_sharedInitialization;
- (void)_reloadIntegers;
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;
- (void)_respondToBoundsChange;

- (void)_cleanupCells;
- (void)_layoutAccessories;
- (void)_layoutExtremities;
- (void)_layoutGridView; /* Only call this directly; prefer -setNeedsLayout */
- (void)_layoutVisibleCells;

- (void)_incrementVisibleCellsByAmount:(NSUInteger)amount fromIndexPath:(KKIndexPath *)indexPath throughIndexPath:(KKIndexPath *)throughPath;

- (KKGridViewCell *)_loadCellAtVisibleIndexPath:(KKIndexPath *)indexPath;
- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath;

- (void)_performUpdate:(KKGridViewUpdate *)update withVisiblePaths:(NSArray *)indexPaths;

- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath;

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
    self.delaysContentTouches = NO;
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

- (id)initWithFrame:(CGRect)frame dataSource:(id <KKGridViewDataSource>)dataSource delegate:(id <KKGridViewDelegate>)delegate
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
    [self setNeedsLayout];
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

- (void)_layoutGridView
{
    // TODO: add an update method so cells can be updated by datasource
    dispatch_sync(_renderQueue, ^(void) {
        [self _layoutVisibleCells];
        [self _layoutAccessories];
        [self _layoutExtremities];
        _markedForDisplay = NO;
        _staggerForInsertion = NO;
    });
}

#pragma mark - Calculation

- (CGFloat)_sectionHeightsCombinedUpToSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    for (NSUInteger index = 0; index < section && index < _sectionHeights.size(); index++) {
        height += _sectionHeights[index];
    }
    return height;
}

- (CGFloat)_heightForSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    
    if (_headerHeights.size() > section) {
        height += _headerHeights[section];   
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
    CGFloat yPosition = _cellPadding.height + _gridHeaderView.frame.size.height;
    CGFloat xPosition = _cellPadding.width;
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        if (_sectionHeights.size() > 0) {
            yPosition += _sectionHeights[section];
        } else {
            yPosition += [self _heightForSection:section];
        }
    }
    
    if (indexPath.section < _headerHeights.size()) {
        yPosition += _headerHeights[indexPath.section];
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

#pragma mark - Internal Layout Methods

- (void)_cleanupCells
{
    const CGRect visibleBounds = { self.contentOffset, self.bounds.size };
    
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
}

- (void)_layoutAccessories
{
//    if (_staggerForInsertion) {
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDuration:0.25];
//        [UIView setAnimationsEnabled:YES];
//    }
    
    const CGRect visibleBounds = { self.contentOffset, self.bounds.size };
    CGFloat offset = self.contentOffset.y;
    
    for (KKGridViewHeader *header in _headerViews) {
        CGRect f = header.view.frame;
        f.size.width = visibleBounds.size.width;
        CGFloat sectionY = header->stickPoint;
        
        if (sectionY <= offset && offset > 0.0f) {
            f.origin.y = offset;
            
            KKGridViewHeader *sectionTwo = [_headerViews count] > header->section + 1 ? [_headerViews objectAtIndex:header->section + 1] : nil;
            if (sectionTwo != nil) {
                CGFloat sectionTwoHeight = sectionTwo.view.frame.size.height;
                CGFloat sectionTwoY = sectionTwo->stickPoint;
                if ((offset + sectionTwoHeight) >= sectionTwoY) {
                    f.origin.y = sectionTwoY - sectionTwoHeight;
                }
            }
        } else {
            f.origin.y = header->stickPoint;
        }
        
        header.view.frame = f;
    }
    
    NSUInteger index = 0;
    for (KKGridViewFooter *footer in _footerViews) {
        CGRect f = [footer.view frame];
        f.size.width = visibleBounds.size.width;
        CGFloat sectionY = footer->stickPoint;
        // height of current section without height of footerView itself
        CGFloat heightOfSection = _sectionHeights[footer->section] - f.size.height;
        // for footerViews we have to work with the bottom of the screen
        CGFloat screenBottom = offset + visibleBounds.size.height;
        
        // determine if current section footer should be displayed sticky
        // this is if current section is visible and the "normal" y-position of the footer
        // isn't further away from the bottom of the screen than it's height
        if (screenBottom > sectionY - heightOfSection && screenBottom - sectionY < f.size.height) {
            // stick footer at bottom of screen
            f.origin.y = offset + visibleBounds.size.height - f.size.height;
            
            // animate second footer
            KKGridViewFooter *sectionTwo = footer->section > 0 ? [_footerViews objectAtIndex:footer->section - 1] : nil;
            if (sectionTwo != nil) {
                CGFloat sectionTwoHeight = sectionTwo.view.frame.size.height;
                CGFloat sectionTwoY = sectionTwo->stickPoint;
                
                // we move the current sticky footer depending on the position of the second footer
                if (screenBottom + sectionTwoHeight >= sectionTwoY && (screenBottom - (sectionTwoY + sectionTwoHeight) < sectionTwo.view.frame.size.height)) {
                    f.origin.y = sectionTwoY + sectionTwoHeight;
                }
            }
            [self bringSubviewToFront:footer.view];
        } else {
            // footer isn't sticky anymore, set originTop to saved position
            f.origin.y = footer->stickPoint;
            [self sendSubviewToBack:footer.view];
        }
        
        footer.view.frame = f;
        index++;
    }
//    if (_staggerForInsertion) {
//        [UIView commitAnimations];
//    }
}

- (void)_layoutExtremities
{
    if (_gridHeaderView != nil) {
        CGRect headerRect = _gridHeaderView.frame;
        headerRect.origin = CGPointZero;
        headerRect.size.width = self.bounds.size.width;
        _gridHeaderView.frame = headerRect;
    }
    
    // layout gridFooterView
    if (_gridFooterView != nil) {
        CGRect footerRect = _gridFooterView.frame;
        footerRect.origin.x = 0.0;
        footerRect.origin.y  = self.contentSize.height - footerRect.size.height;
        footerRect.size.width = self.bounds.size.width;
        _gridFooterView.frame = footerRect;
    }
}

- (void)_layoutVisibleCells
{    
    NSArray *visiblePaths = [self visibleIndexPaths];
    BOOL needsAccessoryReload = NO;
    for (KKIndexPath *indexPath in visiblePaths) {
        if (_updateStack.itemsToUpdate.count > 0) {
            if ([_updateStack hasUpdateForIndexPath:indexPath]) {
                KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
                [self _performUpdate:update withVisiblePaths:visiblePaths];
                [_updateStack removeUpdateForIndexPath:indexPath];
                needsAccessoryReload = YES;
                [self reloadContentSize];
            }
        } else {
            KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
            cell.selected = [_selectedIndexPaths containsObject:indexPath];
            
            if (!cell) {
                cell = [self _loadCellAtVisibleIndexPath:indexPath];
                [self _displayCell:cell atIndexPath:indexPath];
            } else if (_markedForDisplay) {
                if (_staggerForInsertion)
                    [UIView animateWithDuration:0.25 delay:0.1 options:(UIViewAnimationOptionAllowAnimatedContent) animations:^(void) {
                        cell.frame = [self rectForCellAtIndexPath:indexPath];
                    } completion:nil]; 
                
                cell.frame = [self rectForCellAtIndexPath:indexPath];   
            }
        }
    }
    [self _cleanupCells];
    
    if (needsAccessoryReload) {
        [UIView animateWithDuration:0.25 animations:^(void) {
            
            [self reloadContentSize];
            void (^configureAuxiliaryView)(KKGridViewViewInfo *,NSUInteger,CGFloat,CGFloat) = ^(KKGridViewViewInfo *aux, NSUInteger sec, CGFloat pos, CGFloat h)
            {
                aux.view.frame = CGRectMake(0.f, pos, self.bounds.size.width, h);
                aux->stickPoint = pos;
                aux->section = sec;
            };
            
            for (NSUInteger section = 0; section < _numberOfSections; section++) {
                KKGridViewHeader *header = [_headerViews objectAtIndex:section];
                
                CGFloat position = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
                configureAuxiliaryView(header, section,position, _headerHeights[section]);
            }
            for (NSUInteger section = 0; section < _numberOfSections; section++) {
                KKGridViewFooter *footer = [_footerViews objectAtIndex:section];
                
                CGFloat footerHeight = _footerHeights[section];
                CGFloat position = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
                configureAuxiliaryView(footer, section, position, footerHeight);
            }
            
        }];
        
    }
}

- (KKGridViewCell *)_loadCellAtVisibleIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [_dataSource gridView:self cellForItemAtIndexPath:indexPath];
    [_visibleCells setObject:cell forKey:indexPath];
    cell.frame = [self rectForCellAtIndexPath:indexPath];
    return cell;
}

- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath
{
    if (_flags.delegateRespondsToWillDisplayCell)
    {
        [self.gridDelegate gridView:self willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    
    [self addSubview:cell];
    [self sendSubviewToBack:cell];
}

- (void)_performUpdate:(KKGridViewUpdate *)update withVisiblePaths:(NSArray *)visiblePaths
{
    KKIndexPath *indexPath = update.indexPath;
    _markedForDisplay = YES;
    
    if (update.type == KKGridViewUpdateTypeItemInsert) {
        _staggerForInsertion = YES;
        [self _incrementVisibleCellsByAmount:1 fromIndexPath:indexPath throughIndexPath:[visiblePaths lastObject]];
    }
    
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    cell.selected = [_selectedIndexPaths containsObject:indexPath];
    if (!cell) {
        cell = [_dataSource gridView:self cellForItemAtIndexPath:indexPath];
        [_visibleCells setObject:cell forKey:indexPath];
        cell.frame = [self rectForCellAtIndexPath:indexPath];
        switch (update.animation) {
            case KKGridViewAnimationExplode: {
                cell.alpha = 0.f;
                cell.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
                [self addSubview:cell];
                [self sendSubviewToBack:cell];
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
}

#pragma mark --

- (KKIndexPath *)indexPathForCell:(KKGridViewCell *)cell
{
    for (KKIndexPath *indexPath in [_visibleCells allKeys]) {
        if ([_visibleCells objectForKey:indexPath] == cell)
            return indexPath;
    }
    
    return [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
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

- (void)_incrementVisibleCellsByAmount:(NSUInteger)amount fromIndexPath:(KKIndexPath *)fromPath throughIndexPath:(KKIndexPath *)throughPath
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [_visibleCells enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KKIndexPath *indexPath = (KKIndexPath *)key;
        //        TODO: Switch to NSRange intersection-checking
        if (indexPath.section == fromPath.section) {
            if (([indexPath compare:fromPath] == NSOrderedSame | [indexPath compare:fromPath] == NSOrderedDescending) ) {
                
                indexPath.index++;
            }
        }
        [dictionary setObject:obj forKey:indexPath];
    }];
    
    [_visibleCells removeAllObjects], [_visibleCells setDictionary:dictionary];
}

- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier
{
    NSMutableSet *set = [_reusableCells objectForKey:identifier];
    if (!set) {
        [_reusableCells setObject:[NSMutableSet set] forKey:identifier];
        set = [_reusableCells objectForKey:identifier];;
    }
    [set addObject:cell];
}

- (void)reloadContentSize
{
    [self _reloadIntegers];
    
    NSUInteger oldColumns = _numberOfColumns;
    _numberOfColumns = self.bounds.size.width / (_cellSize.width + _cellPadding.width);
    
    if (oldColumns != _numberOfColumns) {
        _markedForDisplay = YES;
    }
    
    CGSize newContentSize = CGSizeMake(self.bounds.size.width, _gridHeaderView.frame.size.height + _gridFooterView.frame.size.height);
    
    _sectionHeights.clear();
    
    for (NSUInteger i = 0; i < _numberOfSections; ++i) {
        CGFloat _heightForSection = [self _heightForSection:i];
        _sectionHeights.push_back(_heightForSection);
        newContentSize.height += _heightForSection;
    }
    
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
    
    _footerHeights.clear();
    
    if (_flags.dataSourceRespondsToHeightForFooterInSection) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            _footerHeights.push_back([_dataSource gridView:self heightForFooterInSection:section]);
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
    NSMutableArray *indexes = [[NSMutableArray alloc] init];
    
    for (KKIndexPath *indexPath in visiblePaths) {
        CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, cellRect)) {
            [indexes addObject:indexPath];
        }
    }
    
    return indexes;
}

- (void)scrollToItemAtIndexPath:(KKIndexPath *)indexPath animated:(BOOL)animated
{
    [self scrollRectToVisible:[self rectForCellAtIndexPath:indexPath] animated:YES];
}

- (KKIndexPath *)indexPathsForItemAtPoint:(CGPoint)point
{
    NSArray *indexes = [self indexPathsForItemsInRect:(CGRect){ point, {1.f, 1.f } }];
    return ([indexes count] > 0) ? [indexes objectAtIndex:0] : [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    if (_allowsMultipleSelection) {
        if ([_selectedIndexPaths containsObject:indexPath]) {
            [self _deselectItemAtIndexPath:indexPath];
        } else {
            [_selectedIndexPaths addObject:indexPath];
            cell.selected = YES;
        }
    } else {
        for (KKIndexPath *path in _selectedIndexPaths) {
            [self _deselectItemAtIndexPath:path];
        }
        
        [_selectedIndexPaths addObject:indexPath];
        cell.selected = YES;
    }
}

- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath
{
    if (_selectedIndexPaths.count > 0 && _flags.delegateRespondsToWillDeselectItem) {
        KKIndexPath *redirectedPath = [_gridDelegate gridView:self willDeselectItemAtIndexPath:indexPath];
        if (redirectedPath != nil && ![redirectedPath isEqual:indexPath]) {
            indexPath = redirectedPath ? redirectedPath : indexPath;
        }
    }
    
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    if ([_selectedIndexPaths containsObject:indexPath]) {
        [_selectedIndexPaths removeObject:indexPath];
        cell.selected = NO;
    }
    
    if (_flags.delegateRespondsToDidDeselectItem)
    {
        [_gridDelegate gridView:self didDeselectItemAtIndexPath:indexPath];
    }
}

#pragma mark - Touch Handling

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_lastSelectedCell) {
        _lastSelectedCell.selected = NO;
        _lastSelectedCell = nil;
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    KKIndexPath *indexPath = [self indexPathsForItemAtPoint:location];
    
    if (indexPath.index == NSNotFound) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    if (_flags.delegateRespondsToWillSelectItem)
    {
        KKIndexPath *redirectedPath = [_gridDelegate gridView:self willSelectItemAtIndexPath:indexPath];
        if (redirectedPath != nil && ![redirectedPath isEqual:indexPath])
        {
            indexPath = redirectedPath;
            
            _lastSelectedCell.selected = NO;
            _lastSelectedCell = [_visibleCells objectForKey:indexPath];
            [self _selectItemAtIndexPath:indexPath];
        }
    }
    
    if (_flags.delegateRespondsToDidSelectItem) {
        [_gridDelegate gridView:self didSelectItemAtIndexPath:indexPath];
    }
    
    _lastSelectedCell = nil;
    
    [super touchesEnded:touches withEvent:event];
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass:[KKGridViewCell class]]) {
        _lastSelectedCell = (KKGridViewCell *)touch.view;
    }
    
    KKIndexPath *indexPathToSelect = [self indexPathsForItemAtPoint:[touch locationInView:self]];
    
    if (indexPathToSelect.index == NSNotFound) {
        return YES;
    }
    
    [self _selectItemAtIndexPath:indexPathToSelect];
    
    return YES;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    _lastSelectedCell.selected = NO;
    _lastSelectedCell = nil;
    
    return YES;
}

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier 
{
    if (!identifier) return nil;
    
    NSMutableSet *reusableCellsForIdentifier = [_reusableCells objectForKey:identifier];
    
    if ([reusableCellsForIdentifier count] == 0)
        return nil;
    
    KKGridViewCell *reusableCell = [reusableCellsForIdentifier anyObject];
    [reusableCellsForIdentifier removeObject:reusableCell];
    
    [reusableCell prepareForReuse];
    
    return reusableCell;
}

- (NSMutableArray *)visibleIndexPaths
{
    const CGRect visibleBounds = { self.contentOffset, self.bounds.size };
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    KKIndexPath *indexPath = [KKIndexPath indexPathForIndex:0 inSection:0];
    
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        for (NSUInteger index = 0; index < [_dataSource gridView:self numberOfItemsInSection:section]; index++) {
            
            indexPath.section = section;
            indexPath.index = index;
            
            CGRect rect = [self rectForCellAtIndexPath:indexPath];
            if (KKCGRectIntersectsRectVertically(rect, visibleBounds)) {
                [indexPaths addObject:[indexPath copy]];
            } else if (CGRectGetMinY(rect) > CGRectGetMaxY(visibleBounds)) {
                break;
            }
        }
    }
    
    return indexPaths;
}

#pragma mark - Setters

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    if (!allowsMultipleSelection && _allowsMultipleSelection == YES) {
        [_selectedIndexPaths removeAllObjects];
        [UIView animateWithDuration:0.25 animations:^(void) {
            [self setNeedsLayout];
        }];
    }
    _allowsMultipleSelection = allowsMultipleSelection;
}

- (void)setCellPadding:(CGSize)cellPadding
{
    _cellPadding = cellPadding;
    if (_cellSize.width != 0.f && _cellSize.height != 0.f) {
        [self reloadData];
    }
}

- (void)setCellSize:(CGSize)cellSize
{
    _cellSize = cellSize;
    if (_cellPadding.width != 0.f && _cellPadding.height != 0.f) {
        [self reloadData];
    }
}

- (void)setDataSource:(id <KKGridViewDataSource>)dataSource
{
    _dataSource = dataSource;
    _flags.dataSourceRespondsToHeightForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:heightForHeaderInSection:)];
    _flags.dataSourceRespondsToHeightForFooterInSection = [_dataSource respondsToSelector:@selector(gridView:heightForFooterInSection:)];
    _flags.dataSourceRespondsToNumberOfSections = [_dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)];
    _flags.dataSourceRespondsToViewForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:viewForHeaderInSection:)];
    _flags.dataSourceRespondsToViewForFooterInSection = [_dataSource respondsToSelector:@selector(gridView:viewForFooterInSection:)];
}

- (void)setGridDelegate:(id <KKGridViewDelegate>)gridDelegate
{
    _gridDelegate = gridDelegate;
    _flags.delegateRespondsToWillSelectItem = [_gridDelegate respondsToSelector:@selector(gridView:willSelectItemAtIndexPath:)];
    _flags.delegateRespondsToDidSelectItem = [_gridDelegate respondsToSelector:@selector(gridView:didSelectItemAtIndexPath:)];
    _flags.delegateRespondsToWillDeselectItem = [_gridDelegate respondsToSelector:@selector(gridView:willDeselectItemAtIndexPath:)];
    _flags.delegateRespondsToDidDeselectItem = [_gridDelegate respondsToSelector:@selector(gridView:didDeselectItemAtIndexPath:)];
    _flags.delegateRespondsToWillDisplayCell = [_gridDelegate respondsToSelector:@selector(gridView:willDisplayCell:forItemAtIndexPath:)];
}

- (void)setGridHeaderView:(UIView *)gridHeaderView
{
    if (gridHeaderView != _gridHeaderView) {
        [_gridHeaderView removeFromSuperview];
        _gridHeaderView = gridHeaderView;
        
        [self addSubview:gridHeaderView];
        [self setNeedsLayout];
    }
}

- (void)setGridFooterView:(UIView *)gridFooterView
{
    if (_gridFooterView != gridFooterView) {
        _gridFooterView = gridFooterView;
        
        [self addSubview:gridFooterView];
        [self setNeedsLayout];
    }
}

#pragma mark - General

- (void)reloadData
{
    [self reloadContentSize];
    
    void (^clearAuxiliaryViews)(__strong NSMutableArray *&) = ^(__strong NSMutableArray *&views)
    {
        [[views valueForKey:@"view"] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [views removeAllObjects];
        
        if (!views)
        {
            views = [[NSMutableArray alloc] initWithCapacity:_numberOfSections];
        }
    };
    
    void (^configureAuxiliaryView)(KKGridViewViewInfo *,NSUInteger,CGFloat,CGFloat) = ^(KKGridViewViewInfo *aux, NSUInteger sec, CGFloat pos, CGFloat h)
    {
        aux.view.frame = CGRectMake(0.f, pos, self.bounds.size.width, h);
        aux->stickPoint = pos;
        aux->section = sec;
    };
    
    if (_flags.dataSourceRespondsToViewForHeaderInSection && _flags.dataSourceRespondsToHeightForHeaderInSection) {
        clearAuxiliaryViews(_headerViews);
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            UIView *view = [_dataSource gridView:self viewForHeaderInSection:section];
            KKGridViewHeader *header = [[KKGridViewHeader alloc] initWithView:view];
            [_headerViews addObject:header];
            
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
            configureAuxiliaryView(header, section,position, _headerHeights[section]);
            
            [self addSubview:header.view];
        }
    }
    
    if (_flags.dataSourceRespondsToViewForFooterInSection && _flags.dataSourceRespondsToHeightForFooterInSection) {
        clearAuxiliaryViews(_footerViews);
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            UIView *view = [_dataSource gridView:self viewForFooterInSection:section];
            KKGridViewFooter *footer = [[KKGridViewFooter alloc] initWithView:view];
            [_footerViews addObject:footer];
            
            CGFloat footerHeight = _footerHeights[section];
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
            configureAuxiliaryView(footer, section, position, footerHeight);
            
            [self addSubview:footer.view];
        }
    }
    
    for (KKGridViewCell *cell in [_visibleCells allValues]) {
        NSMutableSet *set = [_reusableCells objectForKey:cell.reuseIdentifier];
        [set addObject:cell];
    }
    
    [[_visibleCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_visibleCells removeAllObjects];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    for (KKIndexPath *path in indexPaths) {
        KKGridViewCell *cell = [_visibleCells objectForKey:path];
        if (cell) {
            [cell removeFromSuperview];
            [_visibleCells removeObjectForKey:path];
        }
        
        cell = [self _loadCellAtVisibleIndexPath:path];
        [self _displayCell:cell atIndexPath:path];
    }
}

@end
