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

#define KKGridViewDefaultAnimationStaggerInterval 0.025

@interface KKGridView () {
    // View-wrapper containers
    NSMutableArray *_footerViews;
    NSMutableArray *_headerViews;
    
    // Metrics - C Structs are used to improve performance
    CGFloat *_footerHeights;
    CGFloat *_headerHeights;
    CGFloat *_sectionHeights;
    NSUInteger *_sectionItemCounts;
    
    // Cell containers
    NSMutableDictionary *_reusableCells;
    NSMutableDictionary *_visibleCells;
    
    // Selection
    NSMutableSet *_selectedIndexPaths;
    UITapGestureRecognizer *_selectionRecognizer;
    
    // Relating to updates/layout changes
    BOOL _markedForDisplay; // Relayout or not
    BOOL _staggerForInsertion; // Animate items or not
    BOOL _needsAccessoryReload;
    KKGridViewUpdateStack *_updateStack; // Update manager
}

// Initialization
- (void)_sharedInitialization;

// Reloading
- (void)_reloadIntegers;
- (void)_commonReload;
- (void)_softReload;

// Torch-passers
- (void)_respondToBoundsChange;

// Internal Layout
- (void)_cleanupCells;
- (void)_layoutAccessories;
- (void)_layoutExtremities;
- (void)_layoutGridView; /* Only call this directly; prefer -setNeedsLayout */
- (void)_layoutVisibleCells;
- (void)_layoutModelCells;
- (void)_configureAuxiliaryView:(KKGridViewViewInfo *)headerOrFooter inSection:(NSUInteger)section withStickPoint:(CGFloat)stickPoint height:(CGFloat)height;
- (void)_performRemainingUpdatesModelOnly;

// Metrics
- (CGFloat)_heightForSection:(NSUInteger)section;
- (CGFloat)_sectionHeightsCombinedUpToSection:(NSUInteger)section;

// Cell Management
- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath withAnimation:(KKGridViewAnimation)animation;
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;

// Model modifiers
- (void)_incrementCellsAtIndexPath:(KKIndexPath *)fromPath toIndexPath:(KKIndexPath *)toPath byAmount:(NSUInteger)amount amountNegative:(BOOL)negative;

// Internal getters relating to cells
- (KKGridViewCell *)_loadCellAtVisibleIndexPath:(KKIndexPath *)indexPath;
- (NSMutableSet *)_reusableCellSetForIdentifier:(NSString *)identifier;
- (KKIndexPath *)_lastIndexPathForSection:(NSUInteger)section;

// Selection
- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_handleSelection:(UITapGestureRecognizer *)recognizer;

@end

@implementation KKGridView

// Main Properties
@synthesize allowsMultipleSelection = _allowsMultipleSelection;
@synthesize cellPadding = _cellPadding;
@synthesize cellSize = _cellSize;
@synthesize gridFooterView = _gridFooterView;
@synthesize gridHeaderView = _gridHeaderView;
@synthesize numberOfColumns = _numberOfColumns;
@synthesize numberOfSections = _numberOfSections;
@synthesize backgroundView = _backgroundView;

// Data Source Blocks
@synthesize cellBlock = _cellBlock;
@synthesize numberOfSectionsBlock = _numberOfSectionsBlock;
@synthesize numberOfItemsInSectionBlock = _numberOfItemsInSectionBlock;
@synthesize heightForHeaderInSectionBlock = _heightForHeaderInSectionBlock;
@synthesize heightForFooterInSectionBlock = _heightForFooterInSectionBlock;
@synthesize viewForHeaderInSectionBlock = _viewForHeaderInSectionBlock;
@synthesize viewForFooterInSectionBlock = _viewForFooterInSectionBlock;

// Delegate Blocks
@synthesize didSelectIndexPathBlock = _didSelectIndexPathBlock;
@synthesize willSelectItemAtIndexPathBlock = _willSelectItemAtIndexPathBlock;
@synthesize willDeselectItemAtIndexPathBlock = _willDeselectItemAtIndexPathBlock;
@synthesize didDeselectIndexPathBlock = _didDeselectIndexPathBlock;
@synthesize willDisplayCellAtPathBlock = _willDisplayCellAtPathBlock;

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
    
    //    Set up defaults
    self.cellSize = CGSizeMake(75.f, 75.f);
    self.scrollsToTop = YES;
    self.cellPadding = CGSizeMake(4.f, 4.f);
    self.allowsMultipleSelection = NO;
    self.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Cleanup

- (void)dealloc
{
    free(_footerHeights);
    free(_headerHeights);
    free(_sectionHeights);
    free(_sectionItemCounts);
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

- (void) setContentInset:(UIEdgeInsets)contentInset {
    UIEdgeInsets oldInsets = self.contentInset;
    [super setContentInset:contentInset];
    if (!UIEdgeInsetsEqualToEdgeInsets(oldInsets, contentInset)) {
        [self _respondToBoundsChange];
    }
}

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

- (void)setCellBlock:(KKGridViewCellForItemAtIndexPath)cellBlock
{
    _cellBlock = [cellBlock copy];
    [self reloadData];
}

- (void)setNumberOfSectionsBlock:(KKGridViewNumberOfSections)numberOfSectionsBlock
{
    _numberOfSectionsBlock = [numberOfSectionsBlock copy];
    [self reloadData];
}

- (void)setNumberOfItemsInSectionBlock:(KKGridViewNumberOfItemsInSection)numberOfItemsInSectionBlock
{
    _numberOfItemsInSectionBlock = [numberOfItemsInSectionBlock copy];
    [self reloadData];
}

- (void)setHeightForFooterInSectionBlock:(KKGridViewHeightForFooterInSection)heightForFooterInSectionBlock
{
    _heightForFooterInSectionBlock = [heightForFooterInSectionBlock copy];
    [self reloadData];
}

- (void)setHeightForHeaderInSectionBlock:(KKGridViewHeightForHeaderInSection)heightForHeaderInSectionBlock
{
    _heightForHeaderInSectionBlock = [heightForHeaderInSectionBlock copy];
    [self reloadData];
}

- (void)setViewForHeaderInSectionBlock:(KKGridViewViewForHeaderInSection)viewForHeaderInSectionBlock
{
    _viewForHeaderInSectionBlock = [viewForHeaderInSectionBlock copy];
    [self reloadData];
}

- (void)setViewForFooterInSectionBlock:(KKGridViewViewForFooterInSection)viewForFooterInSectionBlock
{
    _viewForFooterInSectionBlock = [viewForFooterInSectionBlock copy];
    [self reloadData];
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
    _needsAccessoryReload = NO;
}

#pragma mark - Private Layout Methods

- (void)_layoutAccessories
{
    CGRect visibleBounds = CGRectMake(self.contentOffset.x + self.contentInset.left, self.contentOffset.y + self.contentInset.top, self.bounds.size.width - self.contentInset.right, self.bounds.size.height - self.contentInset.bottom);
    CGFloat offset = self.contentOffset.y + self.contentInset.top;
    
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
    
    offset = self.contentOffset.y;
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
    NSUInteger index = 0;
    
    for (KKIndexPath *indexPath in visiblePaths) {
        //      Updates
        KKGridViewAnimation animation = KKGridViewAnimationNone;
        if ([_updateStack hasUpdateForIndexPath:indexPath]) {
            _needsAccessoryReload = YES;
            _markedForDisplay = YES;
            _staggerForInsertion = YES;
            
            KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
            animation = update.animation;
            
            NSArray *newVisiblePaths = [self visibleIndexPaths];
            
            if (update.type == KKGridViewUpdateTypeItemInsert) {
                [self _incrementCellsAtIndexPath:indexPath toIndexPath:[self _lastIndexPathForSection:indexPath.section] byAmount:1 amountNegative:NO];
            } else if (update.type == KKGridViewUpdateTypeItemDelete) {
                [self _incrementCellsAtIndexPath:indexPath toIndexPath:[self _lastIndexPathForSection:indexPath.section] byAmount:1 amountNegative:YES];
            } else if (update.type == KKGridViewUpdateTypeItemMove) {
                [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
                    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
                    cell.frame = [self rectForCellAtIndexPath:update.destinationPath];
                }];
                [self _incrementCellsAtIndexPath:update.destinationPath toIndexPath:[self _lastIndexPathForSection:indexPath.section] byAmount:1 amountNegative:NO];
                //                [self _incrementCellsAtIndexPath:update.indexPath toIndexPath:[self _lastIndexPathForSection:indexPath.section] byAmount:1 amountNegative:NO];
                [_updateStack removeUpdate:update];
            }
            
            NSMutableSet *replacementSet = [[NSMutableSet alloc] initWithCapacity:[_selectedIndexPaths count]];
            [_selectedIndexPaths enumerateObjectsUsingBlock:^(KKIndexPath *keyPath, BOOL *stop) {
                if (update.type == KKGridViewUpdateTypeItemInsert) {
                    if (indexPath.section == keyPath.section && keyPath.index >= indexPath.index) {
                        [replacementSet addObject:[KKIndexPath indexPathForIndex:keyPath.index + 1 inSection:keyPath.section]];
                    } else {
                        [replacementSet addObject:keyPath];
                    }
                } else if (update.type == KKGridViewUpdateTypeItemDelete) {
                    if (indexPath.section == keyPath.section && indexPath.index < keyPath.index && keyPath.index != 0) {
                        [replacementSet addObject:[KKIndexPath indexPathForIndex:keyPath.index - 1 inSection:keyPath.section]];
                    } else if (keyPath.index != 0) {
                        [replacementSet addObject:keyPath];
                    }
                } else {
                    [replacementSet addObject:keyPath];
                }
            }];
            [_selectedIndexPaths setSet:replacementSet];
            
            [self reloadContentSize];
            
            if (![newVisiblePaths isEqual:visiblePaths]) {
                NSMutableArray *difference = [[[_visibleCells allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                [difference removeObjectsInArray:visiblePaths];
                for (KKIndexPath *keyPath in difference) {
                    KKGridViewCell *cell = [_visibleCells objectForKey:keyPath];
                    cell.selected = [_selectedIndexPaths containsObject:keyPath];
                    if (_staggerForInsertion) {
                        [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0.0015 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
                            cell.frame = [self rectForCellAtIndexPath:indexPath];
                        } completion:nil];
                    } else {
                        cell.frame = [self rectForCellAtIndexPath:indexPath];
                    }
                }
            }
        }
        KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
        if (!cell) {
            cell = [self _loadCellAtVisibleIndexPath:indexPath];
            [self _displayCell:cell atIndexPath:indexPath withAnimation:animation];
        } else if (_markedForDisplay) {
            if (_staggerForInsertion) {
                [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:(index + 1) * 0.0015 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    cell.frame = [self rectForCellAtIndexPath:indexPath];
                } completion:nil];
            } else {
                cell.frame = [self rectForCellAtIndexPath:indexPath];
            }
        }
        cell.selected = [_selectedIndexPaths containsObject:indexPath];
        
        index++;
    }
    [self _cleanupCells];
    
    if (_needsAccessoryReload) {
        [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            [self reloadContentSize];
            
            for (NSUInteger section = 0; section < _numberOfSections; section++) {
                KKGridViewHeader *header = nil;
                if (_headerViews.count > section && (header = [_headerViews objectAtIndex:section])) {
                    CGFloat headerPosition = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
                    [self _configureAuxiliaryView:header inSection:section withStickPoint:headerPosition height:_headerHeights[section]];
                }
                
                KKGridViewFooter *footer = nil;
                if (_footerViews.count > section && (header = [_footerViews objectAtIndex:section])) {
                    CGFloat footerHeight = _footerHeights[section];
                    CGFloat footerPosition = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
                    [self _configureAuxiliaryView:footer inSection:section withStickPoint:footerPosition height:footerHeight];
                }
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
        cell.frame = (CGRect){CGPointZero, _cellSize};
        [cell removeFromSuperview];
        [_visibleCells removeObjectForKey:path];
    }
}

- (void)_respondToBoundsChange
{
    [self reloadData];
    [self setNeedsLayout];
}

- (void)_layoutModelCells
{
    [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
        [_visibleCells enumerateKeysAndObjectsUsingBlock:^(KKIndexPath *keyPath, KKGridViewCell *cell, BOOL *stop) {
            cell.frame = [self rectForCellAtIndexPath:keyPath]; 
        }];
    }];
}

- (void)_performRemainingUpdatesModelOnly
{
    NSArray *filteredArray = [_updateStack.itemsToUpdate filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"animating == NO"]];
    if (filteredArray.count > 0) {
        [_updateStack.itemsToUpdate removeObjectsInArray:filteredArray];
        CGFloat yPosition = self.contentOffset.y;
        [self _softReload];
        self.contentOffset = CGPointMake(0.f, self.contentOffset.y > yPosition ? self.contentOffset.y - yPosition : self.contentOffset.y + (self.contentOffset.y - yPosition));
    }
}

- (void)_configureAuxiliaryView:(KKGridViewViewInfo *)headerOrFooter inSection:(NSUInteger)section withStickPoint:(CGFloat)stickPoint height:(CGFloat)height
{
    headerOrFooter.view.frame = CGRectMake(0.f, stickPoint, self.bounds.size.width, height);
    headerOrFooter->stickPoint = stickPoint;
    headerOrFooter->section = section;
}

#pragma mark - Metric Calculation

- (CGFloat)_sectionHeightsCombinedUpToSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    for (NSUInteger index = 0; index < section && index < _numberOfSections; index++) {
        height += _sectionHeights[index];
    }
    return height;
}

- (CGFloat)_heightForSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    
    if (_numberOfSections > section) {
        height += _headerHeights[section];
        height += _footerHeights[section];
    }
    
    CGFloat numberOfRows = 0.f;
    
    if (_numberOfSections > 0) {
        numberOfRows = ceilf(_sectionItemCounts[section] / [[NSNumber numberWithUnsignedInt:_numberOfColumns] floatValue]);
    } else {
        if (_numberOfItemsInSectionBlock)
            numberOfRows = ceilf(_numberOfItemsInSectionBlock(self, section) / (CGFloat)_numberOfColumns);
    }
    
    height += numberOfRows * (_cellSize.height + _cellPadding.height);
    height += _cellPadding.height;
    
    return height;
}

#pragma mark - Cell Management

- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath withAnimation:(KKGridViewAnimation)animation
{
    if (_willDisplayCellAtPathBlock) {
        _willDisplayCellAtPathBlock(self, cell, indexPath);
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
    KKGridViewCell *cell = _cellBlock(self, indexPath);
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

#pragma mark - Internal IndexPath Getters

- (KKIndexPath *)_lastIndexPathForSection:(NSUInteger)section
{
    return [KKIndexPath indexPathForIndex:_numberOfItemsInSectionBlock(self, section) inSection:section];
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

- (NSArray *)indexPathsForItemsInRect:(CGRect)rect
{
    NSArray *visiblePaths = [self visibleIndexPaths];
    NSMutableArray *indexes = [[NSMutableArray alloc] init];
    
    for (KKIndexPath *indexPath in visiblePaths) {
        CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, cellRect))
            [indexes addObject:indexPath];
        
    }
    
    return indexes;
}

- (KKIndexPath *)indexPathsForItemAtPoint:(CGPoint)point
{
    NSArray *indexes = [self indexPathsForItemsInRect:(CGRect){ point, {1.f, 1.f } }];
    return ([indexes count] > 0) ? [indexes objectAtIndex:0] : [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath
{
    CGPoint point = { 
        _cellPadding.width,
        _cellPadding.height + _gridHeaderView.frame.size.height,
    };
    
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        if (_numberOfSections > 0) {
            point.y += _sectionHeights[section];
        } else {
            point.y += [self _heightForSection:section];
        }
    }
    
    if (indexPath.section < _numberOfSections) {
        point.y += _headerHeights[indexPath.section];
    }
    
    NSInteger row = floor(indexPath.index / _numberOfColumns);
    NSInteger column = indexPath.index - (row * _numberOfColumns);
    
    point.y += (row * (_cellSize.height + _cellPadding.height));
    point.x += (column * (_cellSize.width + _cellPadding.width));
    
    return (CGRect){point, _cellSize};
}

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
    const CGRect visibleBounds = {self.contentOffset, self.bounds.size};
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    KKIndexPath *indexPath = [KKIndexPath indexPathForIndex:0 inSection:0];
    
    for (NSUInteger section = 0; section < _numberOfSections; section++) {
        for (NSUInteger index = 0; index < _numberOfItemsInSectionBlock(self, section); index++) {
            
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

#pragma mark - Model Modifiers

- (void)_incrementCellsAtIndexPath:(KKIndexPath *)fromPath toIndexPath:(KKIndexPath *)toPath byAmount:(NSUInteger)amount amountNegative:(BOOL)negative
{
    NSMutableDictionary *replacement = [[NSMutableDictionary alloc] init];
    [_visibleCells enumerateKeysAndObjectsUsingBlock:^(KKIndexPath *keyPath, KKGridViewCell *cell, BOOL *stop) {
        BOOL set = YES;
        NSUInteger amountForPath = amount;
        if (keyPath.section == fromPath.section) {
            NSComparisonResult pathComparison = [fromPath compare:keyPath];
            NSComparisonResult lastPathComparison = [[self _lastIndexPathForSection:fromPath.section] compare:keyPath];
            
            BOOL indexPathIsLessOrEqual = pathComparison == NSOrderedAscending || pathComparison == NSOrderedSame;
            BOOL lastPathIsGreatorOrEqual = lastPathComparison == NSOrderedDescending || lastPathComparison == NSOrderedSame;
            
            if (indexPathIsLessOrEqual && lastPathIsGreatorOrEqual && negative && pathComparison == NSOrderedSame) {
                set = NO;
                [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
                    cell.alpha = 0.f;
                } completion:^(BOOL finished) {
                    [cell removeFromSuperview];
                }];
            }
            if (!indexPathIsLessOrEqual || !lastPathIsGreatorOrEqual) {
                amountForPath = 0;
            }
        }
        if (set) {
            if (!negative) {     
                [replacement setObject:cell forKey:[KKIndexPath indexPathForIndex:keyPath.section == fromPath.section ? keyPath.index + amountForPath : keyPath.index inSection:keyPath.section]];
            } else {
                [replacement setObject:cell forKey:[KKIndexPath indexPathForIndex:keyPath.section == fromPath.section ? keyPath.index - amountForPath : keyPath.index inSection:keyPath.section]];
            }
        }
    }];
    [_visibleCells setDictionary:replacement];
}

#pragma mark - Item Editing

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    for (KKIndexPath *indexPath in [indexPaths sortedArrayUsingSelector:@selector(compare:)])
        [_updateStack addUpdate:[KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemInsert animation:animation]];
    
    _staggerForInsertion = YES;
    _markedForDisplay = YES;
    [self _layoutGridView];
    NSArray *unaffected = [_updateStack.itemsToUpdate filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"animating == NO"]];
    NSArray *visiblePaths = [self visibleIndexPaths];
    if (unaffected.count > 0) {
        for (KKGridViewUpdate *update in unaffected) {
            //      Updates
            KKIndexPath *indexPath = update.indexPath;
            KKGridViewAnimation animation = KKGridViewAnimationNone;
            if ([_updateStack hasUpdateForIndexPath:indexPath]) {
                _markedForDisplay = YES;
                _staggerForInsertion = YES;
                _needsAccessoryReload = YES;
                
                KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
//                animation = update.animation;
                
                NSArray *newVisiblePaths = [self visibleIndexPaths];
                
                if (update.type == KKGridViewUpdateTypeItemInsert) {
                    [self _incrementCellsAtIndexPath:indexPath toIndexPath:[self _lastIndexPathForSection:indexPath.section] byAmount:1 amountNegative:NO];
                } else if (update.type == KKGridViewUpdateTypeItemDelete) {
                    [self _incrementCellsAtIndexPath:indexPath toIndexPath:[self _lastIndexPathForSection:indexPath.section] byAmount:1 amountNegative:YES];
                }
                
                NSMutableSet *replacementSet = [[NSMutableSet alloc] initWithCapacity:[_selectedIndexPaths count]];
                [_selectedIndexPaths enumerateObjectsUsingBlock:^(KKIndexPath *keyPath, BOOL *stop) {
                    if (update.type == KKGridViewUpdateTypeItemInsert) {
                        if (indexPath.section == keyPath.section) {
                            [replacementSet addObject:[KKIndexPath indexPathForIndex:keyPath.index + 1 inSection:keyPath.section]];
                        } else {
                            [replacementSet addObject:keyPath];
                        }
                    } else if (update.type == KKGridViewUpdateTypeItemDelete) {
                        if (indexPath.section == keyPath.section) {
                            if (keyPath.index - 1 > -1)
                                [replacementSet addObject:[KKIndexPath indexPathForIndex:keyPath.index - 1 inSection:keyPath.section]];
                        } else {
                            [replacementSet addObject:keyPath];
                        }
                    } else {
                        [replacementSet addObject:keyPath];
                    }
                }];
                [_selectedIndexPaths setSet:replacementSet];
                
                [self reloadContentSize];
                [_updateStack removeUpdate:update];
                
                if (![newVisiblePaths isEqual:visiblePaths]) {
                    NSMutableArray *difference = [[[_visibleCells allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                    [difference removeObjectsInArray:visiblePaths];
                    for (KKIndexPath *keyPath in difference) {
                        KKGridViewCell *cell = [_visibleCells objectForKey:keyPath];
                        cell.selected = [_selectedIndexPaths containsObject:keyPath];
                        if (_staggerForInsertion) {
                            [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0.0015 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
                                cell.frame = [self rectForCellAtIndexPath:indexPath];
                            } completion:nil];
                        } else {
                            cell.frame = [self rectForCellAtIndexPath:indexPath];
                        }
                    }
                }
            }
        }
        [self _cleanupCells];
        
        [self _layoutGridView];
        
    }
    [self _performRemainingUpdatesModelOnly];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    for (KKIndexPath *indexPath in [indexPaths sortedArrayUsingSelector:@selector(compare:)])
        [_updateStack addUpdate:[KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemDelete animation:animation]];
    
    _staggerForInsertion = YES;
    _markedForDisplay = YES;
    [self _layoutGridView];
    [self _performRemainingUpdatesModelOnly];
}

- (void)moveItemAtIndexPath:(KKIndexPath *)indexPath toIndexPath:(KKIndexPath *)newIndexPath
{
    KKGridViewUpdate *update = [KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemMove animation:KKGridViewAnimationNone];
    update.destinationPath = newIndexPath;
    [_updateStack addUpdate:update];
    
    _staggerForInsertion = YES;
    _markedForDisplay = YES;
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

#pragma mark - Reloading

- (void)_commonReload
{
    [self reloadContentSize];
    
    void (^clearAuxiliaryViews)(__strong NSMutableArray **) = ^(__strong NSMutableArray **views)
    {
        [[*views valueForKey:@"view"] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [*views removeAllObjects];
        
        if (!views)
        {
            *views = [[NSMutableArray alloc] initWithCapacity:_numberOfSections];
        }
    };
    
    if (_heightForHeaderInSectionBlock && _viewForHeaderInSectionBlock) {
        clearAuxiliaryViews(&_headerViews);
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            UIView *view = self.viewForHeaderInSectionBlock(self, section);
            KKGridViewHeader *header = [[KKGridViewHeader alloc] initWithView:view];
            [_headerViews addObject:header];
            
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
            [self _configureAuxiliaryView:header inSection:section withStickPoint:position height:_headerHeights[section]];
            
            [self addSubview:header.view];
        }
    }
    
    if (_heightForFooterInSectionBlock && _viewForFooterInSectionBlock) {
        clearAuxiliaryViews(&_footerViews);
        
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            UIView *view = _viewForFooterInSectionBlock(self, section);
            KKGridViewFooter *footer = [[KKGridViewFooter alloc] initWithView:view];
            [_footerViews addObject:footer];
            
            CGFloat footerHeight = _footerHeights[section];
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
            [self _configureAuxiliaryView:footer inSection:section withStickPoint:position height:footerHeight];
            
            [self addSubview:footer.view];
        }
    }
}

- (void)reloadData
{
    [self _commonReload];
    // cells are saved in _reusableCells container to re-use them later on
    for (KKGridViewCell *cell in [_visibleCells allValues]) {
        NSMutableSet *set = [self _reusableCellSetForIdentifier:cell.reuseIdentifier];
        [set addObject:cell];
    }
    
    [[_visibleCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_visibleCells removeAllObjects];
}

- (void)_softReload
{
    [self _commonReload];
    
    [self _layoutModelCells];
    [self _cleanupCells];
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
    
    free(_sectionHeights);
    _sectionHeights = (CGFloat *)calloc(_numberOfSections, sizeof(CGFloat));
    
    for (NSUInteger i = 0; i < _numberOfSections; ++i) {
        CGFloat heightForSection = [self _heightForSection:i];
        _sectionHeights[i] = heightForSection;
        newContentSize.height += heightForSection;
    }
    
    self.contentSize = newContentSize;
}

- (void)_reloadIntegers
{
    if (_numberOfSectionsBlock) {
        _numberOfSections = _numberOfSectionsBlock(self);
    } else {
        _numberOfSections = 1;
    }
    
    free(_headerHeights);
    _headerHeights = (CGFloat *)calloc(_numberOfSections, sizeof(CGFloat));
    
    if (_heightForHeaderInSectionBlock) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            _headerHeights[section] = _heightForHeaderInSectionBlock(self, section);
        }
    }
    
    free(_footerHeights);
    _footerHeights = (CGFloat *)calloc(_numberOfSections, sizeof(CGFloat));
    
    if (_heightForFooterInSectionBlock) {
        for (NSUInteger section = 0; section < _numberOfSections; section++) {
            _footerHeights[section] = _heightForFooterInSectionBlock(self, section);
        }
    }
    
    free(_sectionItemCounts);
    _sectionItemCounts = (NSUInteger *)calloc(_numberOfSections, sizeof(NSUInteger));
    
    if (_numberOfItemsInSectionBlock) {
        for (NSUInteger section = 0; section < _numberOfSections; section++)
            _sectionItemCounts[section] = _numberOfItemsInSectionBlock(self, section);
    }
}

#pragma mark - Positioning

- (void)scrollToItemAtIndexPath:(KKIndexPath *)indexPath animated:(BOOL)animated position:(KKGridViewScrollPosition)scrollPosition
{
    if (animated && scrollPosition != KKGridViewScrollPositionNone) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
    }
    
    CGFloat verticalOffset = 0.0;
    
    CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
    CGFloat boundsHeight = self.bounds.size.height - self.contentInset.bottom;
    
    switch (scrollPosition) {
        case KKGridViewScrollPositionTop:
            verticalOffset = CGRectGetMinY(cellRect) + self.contentInset.top;
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

#pragma mark - Public Selection Methods

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

- (KKIndexPath*) indexPathForSelectedCell {
    if (!_allowsMultipleSelection) {
        return [_selectedIndexPaths anyObject];
    } else {
        return nil;
    }
}

- (NSArray *)indexPathsForSelectedCells {
    return [_selectedIndexPaths allObjects];
}

#pragma mark - Internal Selection Methods

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
    if (_didSelectIndexPathBlock) {
        _didSelectIndexPathBlock(self, indexPath);
    }
}

- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath
{
    if (_selectedIndexPaths.count > 0 && _willDeselectItemAtIndexPathBlock) {
        KKIndexPath *redirectedPath = _willDeselectItemAtIndexPathBlock(self, indexPath);
        if (redirectedPath != nil && ![redirectedPath isEqual:indexPath]) {
            indexPath = redirectedPath ? redirectedPath : indexPath;
        }
    }
    
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    if ([_selectedIndexPaths containsObject:indexPath]) {
        [_selectedIndexPaths removeObject:indexPath];
        cell.selected = NO;
    }
    
    if (_didDeselectIndexPathBlock) {
        _didDeselectIndexPathBlock(self, indexPath);
    }
}

#pragma mark - Touch Handling

- (void)_handleSelection:(UITapGestureRecognizer *)recognizer
{    
    KKIndexPath *indexPath = [self indexPathsForItemAtPoint:[recognizer locationInView:self]];
    if (_willSelectItemAtIndexPathBlock)
        indexPath = _willSelectItemAtIndexPathBlock(self, indexPath);

    if (indexPath.index == NSNotFound || indexPath.section == NSNotFound)
        return;
    
    [self _selectItemAtIndexPath:indexPath];
}

@end
