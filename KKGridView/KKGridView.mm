//
//  KKGridView.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridView.h>
#import <KKGridView/KKGridViewViewInfo.h>
#import <KKGridView/KKIndexPath.h>
#import <KKGridView/KKGridViewUpdate.h>
#import <KKGridView/KKGridViewUpdateStack.h>
#import <KKGridView/KKGridViewCell.h>
#import <map>
#import <vector>

#define KKGridViewDefaultAnimationStaggerInterval 0.025

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
    
    NSMutableArray *_footerViews;
    NSMutableArray *_headerViews;
    
    BOOL _markedForDisplay;
    
    std::vector<CGFloat> _footerHeights;
    std::vector<CGFloat> _headerHeights;
    std::vector<CGFloat> _sectionHeights;
    std::vector<NSUInteger> _sectionItemCount;
    
    NSMutableDictionary *_reusableCells;
    NSMutableDictionary *_visibleCells;
    
    NSMutableSet *_selectedIndexPaths;
    UITapGestureRecognizer *_selectionRecognizer;
    
    BOOL _staggerForInsertion;
    KKGridViewUpdateStack *_updateStack;
}

- (void)_sharedInitialization;
- (void)_reloadIntegers;
- (void)_respondToBoundsChange;

- (void)_cleanupCells;
- (void)_layoutAccessories;
- (void)_layoutExtremities;
- (void)_layoutGridView; /* Only call this directly; prefer -setNeedsLayout */
- (void)_layoutVisibleCells;

- (CGFloat)_heightForSection:(NSUInteger)section;

- (void)_incrementVisibleCellsByAmount:(NSUInteger)amount fromIndexPath:(KKIndexPath *)indexPath throughIndexPath:(KKIndexPath *)throughPath;

- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath withAnimation:(KKGridViewAnimation)animation;
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;
- (KKGridViewCell *)_loadCellAtVisibleIndexPath:(KKIndexPath *)indexPath;
- (NSMutableSet *)_reusableCellSetForIdentifier:(NSString *)identifier;

- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_handleSelection:(UITapGestureRecognizer *)recognizer;

- (KKIndexPath *)_lastIndexPathForSection:(NSUInteger)section;

- (void)_configureAuxiliaryView:(KKGridViewViewInfo *)headerOrFooter inSection:(NSUInteger)section withStickPoint:(CGFloat)stickPoint height:(CGFloat)height;

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
@synthesize backgroundView = _backgroundView;

#pragma mark - Initialization Methods

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

- (void)_sharedInitialization
{
    _reusableCells = [[NSMutableDictionary alloc] init];
    _visibleCells = [[NSMutableDictionary alloc] init];
    _selectedIndexPaths = [[NSMutableSet alloc] init];
    _updateStack = [[KKGridViewUpdateStack alloc] init];
        
    self.alwaysBounceVertical = YES;
    self.delaysContentTouches = YES;
    self.canCancelContentTouches = YES;
    
    _selectionRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleSelection:)];
    [self addGestureRecognizer:_selectionRecognizer];
}

#pragma mark - Metrics

- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath
{
    CGPoint point = { 
        _cellPadding.width,
        _cellPadding.height + _gridHeaderView.frame.size.height,
    };
    
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        if (_sectionHeights.size() > 0) {
            point.y += _sectionHeights[section];
        } else {
            point.y += [self _heightForSection:section];
        }
    }
    
    if (indexPath.section < _headerHeights.size()) {
        point.y += _headerHeights[indexPath.section];
    }
    
    NSInteger row = floor(indexPath.index / _numberOfColumns);
    NSInteger column = indexPath.index - (row * _numberOfColumns);
    
    point.y += (row * (_cellSize.height + _cellPadding.height));
    point.x += (column * (_cellSize.width + _cellPadding.width));
    
    return (CGRect){ point, _cellSize };
}

#pragma mark - Setters

- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    [super setFrame:frame];
    if (!CGSizeEqualToSize(frame.size, oldFrame.size)) {
        [self _respondToBoundsChange];
    }
}

- (void)setBounds:(CGRect)bounds
{
    CGRect oldBounds = self.bounds;
    [super setBounds:bounds];
    if (!CGSizeEqualToSize(bounds.size, oldBounds.size)) {
        [self _respondToBoundsChange];
    }
}

#pragma mark - Root Layout Methods

- (void)layoutSubviews
{
    [self _layoutGridView];
    [super layoutSubviews];
}

- (void)_layoutGridView
{
    [self _layoutVisibleCells];
    [self _layoutAccessories];
    [self _layoutExtremities];
    _markedForDisplay = NO;
    _staggerForInsertion = NO;
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

#pragma mark - Private Layout Methods

- (void)_layoutAccessories
{
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
        CGRect f = footer.view.frame;
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
            
            // move footer view to right below scroller
            [footer.view removeFromSuperview];
            [self insertSubview:footer.view atIndex:self.subviews.count - 1];
        } else {
            // footer isn't sticky anymore, set originTop to saved position
            f.origin.y = footer->stickPoint;
            [self sendSubviewToBack:footer.view];
        }
        
        footer.view.frame = f;
        index++;
    }
}

- (void)_layoutExtremities
{
    if (_gridHeaderView != nil) {
        CGSize headerSize = _gridHeaderView.frame.size;
        headerSize.width = self.bounds.size.width;
        _gridHeaderView.frame = (CGRect) { .size = headerSize };
    }
    
    // layout gridFooterView
    if (_gridFooterView != nil) {
        CGRect footerRect = _gridFooterView.frame;
        footerRect.origin = (CGPoint) { .y = self.contentSize.height - footerRect.size.height };
        footerRect.size.width = self.bounds.size.width;
        _gridFooterView.frame = footerRect;
    }
}

- (void)_layoutVisibleCells
{    
    NSArray *visiblePaths = [self visibleIndexPaths];
    BOOL needsAccessoryReload = NO;
    NSUInteger index = 0;
    
    for (KKIndexPath *indexPath in visiblePaths) {
        //      Updates
        KKGridViewAnimation animation = KKGridViewAnimationNone;
        if ([_updateStack hasUpdateForIndexPath:indexPath]) {
            needsAccessoryReload = YES;
            _markedForDisplay = YES;
            _staggerForInsertion = YES;
            
            KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
            animation = update.animation;
            NSMutableDictionary *replacement = [[NSMutableDictionary alloc] init];
            
            [_visibleCells enumerateKeysAndObjectsUsingBlock:^(KKIndexPath *keyPath, KKGridViewCell *cell, BOOL *stop) {
                if (keyPath.section == indexPath.section) {
                    NSComparisonResult pathComparison = [indexPath compare:keyPath];
                    NSComparisonResult lastPathComparison = [[self _lastIndexPathForSection:indexPath.section] compare:keyPath];
                    
                    BOOL indexPathIsLessOrEqual = pathComparison == NSOrderedSame || pathComparison == NSOrderedAscending;
                    BOOL lastPathIsGreatorOrEqual = lastPathComparison == NSOrderedDescending || lastPathComparison == NSOrderedSame;
                    
                    if (indexPathIsLessOrEqual && lastPathIsGreatorOrEqual) {
                        if (update.type == KKGridViewUpdateTypeItemInsert) {
                            keyPath.index++;
                        } else if (update.type == KKGridViewUpdateTypeItemDelete) {
                            keyPath.index--;
                        }
                    }
                }
                [replacement setObject:cell forKey:keyPath];
            }];
            [_visibleCells setDictionary:replacement];
            [self reloadContentSize];
        }
        
        //      Routine
        KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
        cell.selected = [_selectedIndexPaths containsObject:indexPath];
        if (!cell) {
            cell = [self _loadCellAtVisibleIndexPath:indexPath];
            [self _displayCell:cell atIndexPath:indexPath withAnimation:animation];
            cell.indexPath = indexPath;
        } else if (_markedForDisplay) {
            cell.indexPath = indexPath;
            if (_staggerForInsertion) {
                [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut) animations:^{
                    cell.frame = [self rectForCellAtIndexPath:indexPath];
                } completion:nil];
            } else {
                cell.frame = [self rectForCellAtIndexPath:indexPath];
            }
        }
        
        
        index++;
    }
    [self _cleanupCells];
    
    if (needsAccessoryReload) {
        [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0 options:(UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState) animations:^(void) {
            [self reloadContentSize];
            
            for (NSUInteger section = 0; section < _numberOfSections; section++) {
                KKGridViewHeader *header = [_headerViews objectAtIndex:section];
                KKGridViewFooter *footer = [_footerViews objectAtIndex:section];
                
                CGFloat headerPosition = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
                
                CGFloat footerHeight = _footerHeights[section];
                CGFloat footerPosition = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
                
                [self _configureAuxiliaryView:header inSection:section withStickPoint:headerPosition height:_headerHeights[section]];
                [self _configureAuxiliaryView:footer inSection:section withStickPoint:footerPosition height:footerHeight];
            }
        } completion:nil];
        
    }
}

- (void)_cleanupCells
{
    const CGRect visibleBounds = { self.contentOffset, self.bounds.size };
    
    NSMutableArray *cellToRemove = [[NSMutableArray alloc] init];
    
    [_visibleCells enumerateKeysAndObjectsUsingBlock:^(KKIndexPath *indexPath, KKGridViewCell *cell, BOOL *stop) {
        if (!KKCGRectIntersectsRectVertically(cell.frame, visibleBounds)) {
            [cellToRemove addObject:indexPath];
        }
    }];
    
    for (KKIndexPath *path in cellToRemove) {
        KKGridViewCell *cell = [_visibleCells objectForKey:path];
        [self _enqueueCell:cell withIdentifier:cell.reuseIdentifier];
        [cell removeFromSuperview];
        [_visibleCells removeObjectForKey:path];
    }
}

- (void)_respondToBoundsChange
{
    [self reloadData];
    [self setNeedsLayout];
}

#pragma mark - Cell Management

- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath withAnimation:(KKGridViewAnimation)animation
{
    if (_flags.delegateRespondsToWillDisplayCell)
    {
        [self.gridDelegate gridView:self willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    
    if ([_updateStack hasUpdateForIndexPath:indexPath]) {
        KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
        update.animating = YES;
    }
    
    switch (animation) {
        case KKGridViewAnimationExplode: {
            cell.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
            cell.alpha = 0.f;
            break;
        }   
        default:
            break;
    }
    
    [self addSubview:cell];
    [self sendSubviewToBack:cell];
    
    switch (animation) {
        case KKGridViewAnimationExplode: {
            [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
                cell.transform = CGAffineTransformMakeScale(1.f, 1.f);
                cell.alpha = 1.f;
            } completion:^(BOOL finished) {
                [_updateStack removeUpdateForIndexPath:indexPath];
            }];
            break;
        }    
        default:
            break;
    }
    
}

- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier
{
    NSMutableSet *set = [self _reusableCellSetForIdentifier:identifier];
    [set addObject:cell];
}

- (KKGridViewCell *)_loadCellAtVisibleIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [_dataSource gridView:self cellForItemAtIndexPath:indexPath];
    [_visibleCells setObject:cell forKey:indexPath];
    cell.frame = [self rectForCellAtIndexPath:indexPath];
    return cell;
}

// returns the cell container for reusable cells. creates and adds a container object if non exists yet
- (NSMutableSet *)_reusableCellSetForIdentifier:(NSString *)identifier
{
    NSMutableSet *set = [_reusableCells objectForKey:identifier];
    if (!set) {
        [_reusableCells setObject:[NSMutableSet set] forKey:identifier];
        set = [_reusableCells objectForKey:identifier];;
    }
    return set;
}

#pragma mark - Private Getters

- (KKIndexPath *)_lastIndexPathForSection:(NSUInteger)section
{
    return [KKIndexPath indexPathForIndex:[_dataSource gridView:self numberOfItemsInSection:section] inSection:section];
}

#pragma mark - Update Helpers

- (void)_incrementVisibleCellsByAmount:(NSUInteger)amount fromIndexPath:(KKIndexPath *)fromPath throughIndexPath:(KKIndexPath *)throughPath
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [_visibleCells enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KKIndexPath *indexPath = (KKIndexPath *)key;
        if (indexPath.section == fromPath.section) {
            if ([indexPath compare:fromPath] == NSOrderedSame || [indexPath compare:fromPath] == NSOrderedDescending || [indexPath compare:throughPath] == NSOrderedSame) {
                indexPath.index+=amount;
                [dictionary setObject:obj forKey:indexPath];
            }
        } else {
            [dictionary setObject:obj forKey:indexPath];
            
        }
    }];
    
    [_visibleCells removeAllObjects];
    [_visibleCells setDictionary:dictionary];
}

#pragma mark - Public Getters

- (KKIndexPath *)indexPathForCell:(KKGridViewCell *)cell
{
    for (KKIndexPath *indexPath in [_visibleCells allKeys]) {
        if ([_visibleCells objectForKey:indexPath] == cell)
            return indexPath;
    }
    
    return [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

#pragma mark - Item Editing

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    for (KKIndexPath *indexPath in [indexPaths sortedArrayUsingSelector:@selector(compare:)]) {
        [_updateStack addUpdate:[KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemDelete animation:animation]];
    }
    
    [self _layoutGridView];
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    for (KKIndexPath *indexPath in [indexPaths sortedArrayUsingSelector:@selector(compare:)]) {
        [_updateStack addUpdate:[KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemInsert animation:animation]];
    }
    [self _layoutGridView];
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
        [self _displayCell:cell atIndexPath:path withAnimation:KKGridViewAnimationNone];
    }
}

#pragma mark -

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
    
    self.contentSize = newContentSize;
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

- (void)scrollToItemAtIndexPath:(KKIndexPath *)indexPath animated:(BOOL)animated position:(KKGridViewScrollPosition)scrollPosition
{
    if (animated && scrollPosition != KKGridViewScrollPositionNone) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
    }
    
    CGFloat verticalOffset = 0.0;
    
    CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
    CGFloat boundsHeight = self.bounds.size.height;
    
    switch (scrollPosition) {
        case KKGridViewScrollPositionTop:
            verticalOffset = CGRectGetMinY(cellRect);
            break;
        case KKGridViewScrollPositionBottom:
            verticalOffset = CGRectGetMaxY(cellRect) - boundsHeight;
            break;
        case KKGridViewScrollPositionMiddle:
            verticalOffset = CGRectGetMaxY(cellRect) - (boundsHeight * .5f);
            break;
        case KKGridViewScrollPositionNone:
            [self scrollRectToVisible:cellRect animated:animated];
            return;
            break;
        default:
            break;
    }
    
    self.contentOffset = (CGPoint) { .y = verticalOffset };
    
    if (animated)
        [UIView commitAnimations];
}

- (KKIndexPath *)indexPathsForItemAtPoint:(CGPoint)point
{
    NSArray *indexes = [self indexPathsForItemsInRect:(CGRect){ point, {1.f, 1.f } }];
    return ([indexes count] > 0) ? [indexes objectAtIndex:0] : [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

#pragma mark - Selection
// Public

- (void)selectRowsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated
{
    if (!indexPaths)
        return;
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:KKGridViewDefaultAnimationDuration];
    }
    for (KKIndexPath *indexPath in indexPaths) {
        [self _selectItemAtIndexPath:indexPath];
    }
    if (animated)
        [UIView commitAnimations];
}

- (void)deselectRowsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated
{
    if (!indexPaths)
        return;
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:KKGridViewDefaultAnimationDuration];
    }
    for (KKIndexPath *indexPath in indexPaths) {
        [self _deselectItemAtIndexPath:indexPath];
    }
    if (animated)
        [UIView commitAnimations];
}

// Private

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
    if (_flags.delegateRespondsToDidDeselectItem) {
        [_gridDelegate gridView:self didDeselectItemAtIndexPath:indexPath];
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

- (void)_handleSelection:(UITapGestureRecognizer *)recognizer
{    
    KKIndexPath *indexPath = [self indexPathsForItemAtPoint:[recognizer locationInView:self]];
    
    if (indexPath.index == NSNotFound || indexPath.section == NSNotFound)
        return;
    
    [self _selectItemAtIndexPath:indexPath];
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
        [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0 options:(UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState) animations:^(void) {
            [self _layoutGridView];
        } completion:nil];
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
    
    if (_flags.dataSourceRespondsToViewForHeaderInSection && _flags.dataSourceRespondsToHeightForHeaderInSection) {
        clearAuxiliaryViews(_headerViews);
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            UIView *view = [_dataSource gridView:self viewForHeaderInSection:section];
            KKGridViewHeader *header = [[KKGridViewHeader alloc] initWithView:view];
            [_headerViews addObject:header];
            
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
            [self _configureAuxiliaryView:header inSection:section withStickPoint:position height:_headerHeights[section]];
            
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
            [self _configureAuxiliaryView:footer inSection:section withStickPoint:position height:footerHeight];
            
            [self addSubview:footer.view];
        }
    }
    
    // cells are saved in _reusableCells container to re-use them later on
    for (KKGridViewCell *cell in [_visibleCells allValues]) {
        NSMutableSet *set = [self _reusableCellSetForIdentifier:cell.reuseIdentifier];
        [set addObject:cell];
    }
    
    [[_visibleCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_visibleCells removeAllObjects];
}

#pragma mark - Memory Management

- (void)_configureAuxiliaryView:(KKGridViewViewInfo *)headerOrFooter inSection:(NSUInteger)section withStickPoint:(CGFloat)stickPoint height:(CGFloat)height
{
    headerOrFooter.view.frame = CGRectMake(0.f, stickPoint, self.bounds.size.width, height);
    headerOrFooter->stickPoint = stickPoint;
    headerOrFooter->section = section;
}

@end
