//
//  KKGridView.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridView.h>
#import <KKGridView/KKGridViewSectionInfo.h>
#import <KKGridView/KKIndexPath.h>
#import <KKGridView/KKGridViewUpdate.h>
#import <KKGridView/KKGridViewUpdateStack.h>
#import <KKGridView/KKGridViewCell.h>
#import <KKGridView/KKGridViewIndexView.h>
#import <KKGridView/KKGridViewSectionLabel.h>

struct KKSectionMetrics {
    CGFloat footerHeight;
    CGFloat headerHeight;
    CGFloat rowHeight;
    CGFloat sectionHeight;
    NSUInteger itemCount;
};

@interface KKGridView () <UIGestureRecognizerDelegate> {
    // View-wrapper containers
    NSMutableArray *_footerViews;
    NSMutableArray *_rowViews;
    NSMutableArray *_headerViews;
    
    // Metrics
    struct KKMetricsArray {
        struct KKSectionMetrics * const sections;
        NSUInteger const count;
    } _metrics;
    
    // Cell containers
    NSMutableDictionary *_reusableCells;
    NSMutableDictionary *_visibleCells;
    
    // Selection & Highlighting
    NSMutableSet *_selectedIndexPaths;
    UILongPressGestureRecognizer *_selectionRecognizer;
    
    KKIndexPath *_highlightedIndexPath;
    
    // Relating to updates/layout changes
    BOOL _markedForDisplay; // Relayout or not
    BOOL _staggerForInsertion; // Animate items or not
    BOOL _needsAccessoryReload;
    KKGridViewUpdateStack *_updateStack; // Update manager
    
    // DataSource/Delegate flags
    struct {
        unsigned int numberOfSections:1;
        unsigned int titleForHeader:1;
        unsigned int titleForFooter:1;
        unsigned int heightForHeader:1;
        unsigned int heightForFooter:1;
        unsigned int viewForHeader:1;
        unsigned int viewForFooter:1;
        unsigned int viewForRow:1;
        unsigned int sectionIndexTitles:1;
        unsigned int sectionForSectionIndexTitle:1;
    } _dataSourceRespondsTo;
    
    struct {
        unsigned int didSelectItem:1;
        unsigned int willSelectItem:1;
        unsigned int didDeselectItem:1;
        unsigned int willDeselectItem:1;
        unsigned int willDisplayCell:1;
    } _delegateRespondsTo;
    
    KKGridViewIndexView *_indexView;
}

// Initialization
- (void)_sharedInitialization;

// Reloading
- (void)_reloadMetrics;
- (void)_cleanupMetrics;
- (void)_commonReload;
- (void)_softReload;

// Torch-passers
- (void)_respondToBoundsChange;

// Internal Layout
- (void)_cleanupCells;
- (void)_layoutSectionViews;
- (void)_layoutExtremities;
- (void)_layoutGridView; /* Only call this directly; prefer -setNeedsLayout */
- (void)_layoutVisibleCells;
- (void)_layoutModelCells;
- (void)_configureSectionView:(KKGridViewSectionInfo *)headerOrFooter inSection:(NSUInteger)section withStickPoint:(CGFloat)stickPoint height:(CGFloat)height;
- (void)_performRemainingUpdatesModelOnly;
- (KKGridViewAnimation)_handleUpdateForIndexPath:(KKIndexPath *)indexPath visibleIndexPaths:(NSArray *)visibleIndexPaths;

// Metrics
- (CGFloat)_sectionHeightsCombinedUpToSection:(NSUInteger)section;

// Cell Management
- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath withAnimation:(KKGridViewAnimation)animation;
- (void)_enqueueCell:(KKGridViewCell *)cell withIdentifier:(NSString *)identifier;

// Model modifiers
- (void)_incrementCellsAtIndexPath:(KKIndexPath *)fromPath toIndexPath:(KKIndexPath *)toPath byAmount:(NSInteger)amount;

// Internal getters relating to cells
- (KKGridViewCell *)_loadCellAtVisibleIndexPath:(KKIndexPath *)indexPath;
- (NSMutableSet *)_reusableCellSetForIdentifier:(NSString *)identifier;
- (KKIndexPath *)_lastIndexPathForSection:(NSUInteger)section;

// Selection & Highlighting
- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_highlightItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)_cancelHighlighting;
- (void)_handleSelection:(UILongPressGestureRecognizer *)recognizer;
- (void)_deselectAll;

- (UIView *)_viewForHeaderInSection:(NSUInteger)section;
- (UIView *)_viewForFooterInSection:(NSUInteger)section;

// Custom Subviewinsertion
- (void)_insertSubviewBelowScrollbar:(UIView *)view;

// Animation Helpers
+ (void)animateIf:(BOOL)animated duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options block:(void(^)())block;
+ (void)animateIf:(BOOL)animated delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options block:(void(^)())block;
@end

@implementation KKGridView

@synthesize batchUpdating = _batchUpdating;
@synthesize dataSource = _dataSource;
@dynamic delegate;

@synthesize allowsMultipleSelection = _allowsMultipleSelection;
@synthesize backgroundView = _backgroundView;
@synthesize layoutDirection = _layoutDirection;

@synthesize gridFooterView = _gridFooterView;
@synthesize gridHeaderView = _gridHeaderView;

@synthesize cellPadding = _cellPadding;
@synthesize cellSize = _cellSize;
@synthesize numberOfColumns = _numberOfColumns;

@dynamic numberOfSections;

#pragma mark - Initialization Methods

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

// Unimplemented, not sure if it ever will be.

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self _sharedInitialization];
    }
    
    // Doesn't yet support NSCoder
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self _sharedInitialization];
    }
    
    return self;
}

// Basic setup for the grid.

- (void)_sharedInitialization
{
    _reusableCells = [[NSMutableDictionary alloc] init];
    _visibleCells = [[NSMutableDictionary alloc] init];
    _selectedIndexPaths = [[NSMutableSet alloc] init];
    _updateStack = [[KKGridViewUpdateStack alloc] init];
    
    _layoutDirection = KKGridViewLayoutDirectionVertical;
    
    // Set basic UIScrollView properties
    self.alwaysBounceVertical = _layoutDirection ? KKGridViewLayoutDirectionVertical : YES; 
    self.alwaysBounceHorizontal = _layoutDirection != KKGridViewLayoutDirectionVertical; 
    self.delaysContentTouches = YES;
    self.canCancelContentTouches = YES;
    
    _selectionRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleSelection:)];
    _selectionRecognizer.minimumPressDuration = 0.015;
    _selectionRecognizer.delegate = self;
    _selectionRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_selectionRecognizer];
    
    
    // Set up defaults
    self.cellSize = CGSizeMake(75.f, 75.f);
    self.scrollsToTop = YES;
    self.cellPadding = CGSizeMake(4.f, 4.f);
    self.allowsMultipleSelection = NO;
    self.backgroundColor = [UIColor whiteColor];
    
    [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"tracking" options:NSKeyValueObservingOptionNew context:NULL];
}

#pragma mark - Getters

- (NSUInteger)numberOfSections
{
    return _metrics.count > 0 ? _metrics.count : 1;
}

- (NSUInteger)selectedItemCount
{
    return _selectedIndexPaths.count;
}

#pragma mark - Setters

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    if (allowsMultipleSelection == _allowsMultipleSelection)
        return;
    
    // If multiple selection is being disabled, update.
    if (!allowsMultipleSelection) {
        [_selectedIndexPaths removeAllObjects];
        [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0 options:(UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            [self _layoutGridView];
        } completion:nil];
    }
    _allowsMultipleSelection = allowsMultipleSelection;
}

// Sets a background view akin to UITableView (stays in place)

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (backgroundView == _backgroundView)
        return;
    
    [_backgroundView removeFromSuperview];
    _backgroundView = backgroundView;
    _backgroundView.frame = self.bounds;
    
    [self addSubview:_backgroundView];
    [self sendSubviewToBack:_backgroundView];
}

- (void)setBounds:(CGRect)bounds
{
    CGRect oldBounds = self.bounds;
    [super setBounds:bounds];
    if (!CGSizeEqualToSize(bounds.size, oldBounds.size)) {
        [self _respondToBoundsChange];
    }
}

// Adjusts cell padding is applied to each side

- (void)setCellPadding:(CGSize)cellPadding
{
    //    Call for a total recalculation in the case a change as large as these (cell size as well) occurs.
    if (!CGSizeEqualToSize(_cellPadding, cellPadding)) {
        _cellPadding = cellPadding;
        
        [self _layoutModelCells];
        [self reloadData];
    }
}

// Adjust the point-size of each cell.  Defaults to 75x75.

- (void)setCellSize:(CGSize)cellSize
{
    if (!CGSizeEqualToSize(_cellSize, cellSize)) {
        _cellSize = cellSize;
        
        [self _layoutModelCells];
        [self reloadData];
    }
}

// Override of content inset property; applies by changing grid's interpretation of bounds, calls reload.. experimental according to @keichan34, who implemented it.

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    UIEdgeInsets oldInsets = self.contentInset;
    [super setContentInset:contentInset];
    if (!UIEdgeInsetsEqualToEdgeInsets(oldInsets, contentInset)) {
        [self _respondToBoundsChange];
    }
}

- (void)setDataSource:(id<KKGridViewDataSource>)dataSource
{
    if (dataSource != _dataSource)
    {
        _dataSource = dataSource;
#define RESPONDS_TO(sel) [_dataSource respondsToSelector:@selector(sel)]
        _dataSourceRespondsTo.numberOfSections   = RESPONDS_TO(numberOfSectionsInGridView:);
        _dataSourceRespondsTo.titleForHeader     = RESPONDS_TO(gridView:titleForHeaderInSection:);
        _dataSourceRespondsTo.titleForFooter     = RESPONDS_TO(gridView:titleForFooterInSection:);
        _dataSourceRespondsTo.heightForHeader    = RESPONDS_TO(gridView:heightForHeaderInSection:);
        _dataSourceRespondsTo.heightForFooter    = RESPONDS_TO(gridView:heightForFooterInSection:);
        _dataSourceRespondsTo.viewForHeader      = RESPONDS_TO(gridView:viewForHeaderInSection:);
        _dataSourceRespondsTo.viewForFooter      = RESPONDS_TO(gridView:viewForFooterInSection:);
        _dataSourceRespondsTo.viewForRow         = RESPONDS_TO(gridView:viewForRow:inSection:);
        _dataSourceRespondsTo.sectionIndexTitles = RESPONDS_TO(sectionIndexTitlesForGridView:);
        _dataSourceRespondsTo.sectionForSectionIndexTitle = RESPONDS_TO(gridView:sectionForSectionIndexTitle:atIndex:);
#undef RESPONDS_TO
        [self reloadData];
    }
}

// Sets delegate of gridview, inherits from UIScrollViewDelegate for the moment.

- (void)setDelegate:(id<KKGridViewDelegate>)delegate
{
    if (delegate != self.delegate)
    {
        [super setDelegate:delegate];
#define RESPONDS_TO(sel) [self.delegate respondsToSelector:@selector(sel)]
        _delegateRespondsTo.didSelectItem    = RESPONDS_TO(gridView:didSelectItemAtIndexPath:);
        _delegateRespondsTo.willSelectItem   = RESPONDS_TO(gridView:willSelectItemAtIndexPath:);
        _delegateRespondsTo.didDeselectItem  = RESPONDS_TO(gridView:didDeselectItemAtIndexPath:);
        _delegateRespondsTo.willDeselectItem = RESPONDS_TO(gridView:willDeselectItemAtIndexPath:);
        _delegateRespondsTo.willDisplayCell  = RESPONDS_TO(gridView:willDisplayCell:atIndexPath:);
#undef RESPONDS_TO
    }
}

- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    [super setFrame:frame];
    //    Check if an actual change is needed... repeated in corresponding bounds method.
    if (!CGSizeEqualToSize(frame.size, oldFrame.size)) {
        [self _respondToBoundsChange];
    }
}

- (void)setGridFooterView:(UIView *)gridFooterView
{
    if (gridFooterView == _gridFooterView)
        return;
    
    [_gridFooterView removeFromSuperview];
    _gridFooterView = gridFooterView;
    
    [self addSubview:gridFooterView];
    [self setNeedsLayout];
}

- (void)setGridHeaderView:(UIView *)gridHeaderView
{
    if (gridHeaderView == _gridHeaderView)
        return;
    
    [_gridHeaderView removeFromSuperview];
    _gridHeaderView = gridHeaderView;
    
    [self addSubview:gridHeaderView];
    [self setNeedsLayout];
}

#pragma mark - Batch Editing

// These are pretty simple.. not really sure what else they'd include.

- (void)beginUpdates
{
    _batchUpdating = YES;
}

- (void)endUpdates
{
    _batchUpdating = NO;
}

#pragma mark - Root Layout Methods

- (void)layoutSubviews
{
    [self _layoutGridView];
    [super layoutSubviews];
}

// Ringmaster for the gridview, calls all the other grimy methods to keep everything up-to-date and positioned correctly.

- (void)_layoutGridView
{
    [self _layoutVisibleCells];   
    [self _layoutSectionViews];
    [self _layoutExtremities];
    [self _performRemainingUpdatesModelOnly];
    _markedForDisplay = NO;
    _staggerForInsertion = NO;
    _needsAccessoryReload = NO;
}

#pragma mark - Private Layout Methods

// Manage global grid header and footer views

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

- (void)_respondToBoundsChange
{
    [self reloadData];
    [self setNeedsLayout];
}

// Handle updates in the model so they don't happen as the user scrolls by.. it'll make sense if you comment its code out.

- (void)_performRemainingUpdatesModelOnly
{
    if (_updateStack.itemsToUpdate.count == 0)
        return;
    
    NSArray *filteredArray = [_updateStack.itemsToUpdate filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"animating == NO"]];
    if (filteredArray.count > 0) {
        [_updateStack.itemsToUpdate removeObjectsInArray:filteredArray];
        CGFloat yPosition = self.contentOffset.y;
        [self _softReload];
        self.contentOffset = CGPointMake(0.f, self.contentOffset.y > yPosition ? self.contentOffset.y - yPosition : self.contentOffset.y + (self.contentOffset.y - yPosition));
    }
}

#pragma mark Section Views

// Frame assignments for header and footer views.

- (void)_configureSectionView:(KKGridViewSectionInfo *)headerOrFooter inSection:(NSUInteger)section withStickPoint:(CGFloat)stickPoint height:(CGFloat)height
{
    headerOrFooter.view.frame = CGRectMake(0.f, stickPoint, self.bounds.size.width, height);
    headerOrFooter->stickPoint = stickPoint;
    headerOrFooter->section = section;
}

// Position them for each notch in the scrollview. called a lot, could use optimization probably.

- (void)_layoutSectionViews
{
    // Reposition all the things!... if necessary
    if (_needsAccessoryReload) {
        [UIView animateWithDuration:KKGridViewDefaultAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self reloadContentSize];
            
            for (NSUInteger section = 0; section < _metrics.count; section++) {
                struct KKSectionMetrics sectionMetrics = _metrics.sections[section];
                
                KKGridViewHeader *header = nil;
                if (_headerViews.count > section && (header = [_headerViews objectAtIndex:section])) {
                    CGFloat headerPosition = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
                    [self _configureSectionView:header inSection:section withStickPoint:headerPosition height:sectionMetrics.headerHeight];
                }
                
                KKGridViewFooter *footer = nil;
                if (_footerViews.count > section && (footer = [_footerViews objectAtIndex:section])) {
                    CGFloat footerHeight = sectionMetrics.footerHeight;
                    CGFloat footerPosition = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
                    [self _configureSectionView:footer inSection:section withStickPoint:footerPosition height:footerHeight];
                }
            }
        } completion:nil];
    }
    
    // TODO: Add checking to see if sticking status has actually changed for anything.
    CGRect const visibleBounds = {
        self.contentOffset.x + self.contentInset.left,
        self.contentOffset.y + self.contentInset.top,
        self.bounds.size.width - self.contentInset.right,
        self.bounds.size.height - self.contentInset.bottom
    };
    
    _backgroundView.frame = visibleBounds;
    
    CGFloat offset = self.contentOffset.y + self.contentInset.top;
    
    // If the user is providing titles, they want the default look.
    static UIImage *headerBackgrounds[2] = {0};
    
    if (_dataSourceRespondsTo.titleForHeader || _dataSourceRespondsTo.titleForFooter) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"KKGridView.bundle"];
            NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
            UIImage *(^getBundleImage)(NSString *) = ^(NSString *n) {
                return [UIImage imageWithContentsOfFile:[bundle pathForResource:n ofType:@"png"]];
            };
            
            headerBackgrounds[0] = getBundleImage(@"UISectionListHeaderBackground");
            headerBackgrounds[1] = getBundleImage(@"UISectionListHeaderBackgroundOpaque");
        });
    }
    
    for (KKGridViewHeader *header in _headerViews) {
        // Get basic metrics
        CGRect headerFrame = header.view.frame;
        headerFrame.size.width = visibleBounds.size.width;
        CGFloat sectionY = header->stickPoint;
        
        if (sectionY <= offset && offset >= 0.0f) {
            // Section header is sticky
            headerFrame.origin.y = offset;
            
            if (_dataSourceRespondsTo.titleForHeader)
                header.view.backgroundColor = [UIColor colorWithPatternImage:headerBackgrounds[1]];
            
            KKGridViewHeader *sectionTwo = [_headerViews count] > header->section + 1 ? [_headerViews objectAtIndex:header->section + 1] : nil;
            if (sectionTwo != nil) {
                // Create the section pushing effect
                CGFloat sectionTwoHeight = sectionTwo.view.frame.size.height;
                CGFloat sectionTwoY = sectionTwo->stickPoint;
                if ((offset + sectionTwoHeight) >= sectionTwoY) {
                    headerFrame.origin.y = sectionTwoY - sectionTwoHeight;
                }
            }            
        } else {
            // Put header back to default position
            headerFrame.origin.y = header->stickPoint;
            if (_dataSourceRespondsTo.titleForHeader)
                header.view.backgroundColor = [UIColor colorWithPatternImage:headerBackgrounds[0]];
        }
        
        header.view.frame = headerFrame;
    }
    
    offset = self.contentOffset.y;
    for (KKGridViewFooter *footer in _footerViews) {
        CGRect f = footer.view.frame;
        f.size.width = visibleBounds.size.width;
        CGFloat sectionY = footer->stickPoint;
        // height of current section without height of footerView itself
        CGFloat heightOfSection = _metrics.sections[footer->section].sectionHeight - f.size.height;
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
            
            if (_dataSourceRespondsTo.titleForFooter)
                footer.view.backgroundColor = [UIColor colorWithPatternImage:headerBackgrounds[0]];
            
            // move footer view to right below scroller
            [footer.view removeFromSuperview];
            [self _insertSubviewBelowScrollbar:footer.view];
            
        } else {
            if (_dataSourceRespondsTo.titleForFooter)
                footer.view.backgroundColor = [UIColor colorWithPatternImage:headerBackgrounds[0]];
            
            // footer isn't sticky anymore, set originTop to saved position
            f.origin.y = footer->stickPoint;
            [self insertSubview:footer.view aboveSubview:_backgroundView];
            [self sendSubviewToBack:footer.view];
        }
        
        footer.view.frame = f;
    }
}

#pragma mark Cells

// Remove garbage cells.

- (void)_cleanupCells
{
    CGRect const visibleBounds = { self.contentOffset, self.bounds.size };
    
    typedef struct {
        __unsafe_unretained KKGridViewCell *cell;
        __unsafe_unretained KKIndexPath *path;
    } cell_info_t;
    
    cell_info_t cellsToRemove[_visibleCells.count];
    
    NSUInteger cellCount = 0;
    for (KKIndexPath *path in _visibleCells) {
        KKGridViewCell *cell = [_visibleCells objectForKey:path];
        if (!KKCGRectIntersectsRectVertically(cell.frame, visibleBounds)) {
            cellsToRemove[cellCount] = (cell_info_t){ cell, path };
            cellCount++;
        }
    }
    
    for (NSUInteger i = 0; i < cellCount; ++i) {
        cell_info_t pair = cellsToRemove[i];
        KKGridViewCell *cell = pair.cell;
        
        [self _enqueueCell:cell withIdentifier:cell.reuseIdentifier];
		if (!CGSizeEqualToSize(_cellSize, cell.frame.size))
			cell.frame = (CGRect){.size = _cellSize};
        cell.hidden = YES;
        cell.alpha = 0.;
        
        [_visibleCells removeObjectForKey:pair.path];
    }
}

// Primary cell layout methods..

- (void)_layoutVisibleCells
{    
    NSArray *visiblePaths = [self visibleIndexPaths];
    NSUInteger index = 0;
    
    void (^updateCellFrame)(id,id) = ^(KKGridViewCell *cell, KKIndexPath *indexPath) {
        cell.frame = [self rectForCellAtIndexPath:indexPath]; 
    };
    
    for (KKIndexPath *indexPath in visiblePaths) {
        // Updates
        KKGridViewAnimation animation = KKGridViewAnimationNone;
        BOOL updating = NO;
        
        if ([_updateStack hasUpdateForIndexPath:indexPath] && !_batchUpdating) {
            animation = [self _handleUpdateForIndexPath:indexPath visibleIndexPaths:visiblePaths];
            updating = YES;
        }
        
        KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
        if (!cell) {
            
            cell = [self _loadCellAtVisibleIndexPath:indexPath];
            [self _displayCell:cell atIndexPath:indexPath withAnimation:animation];
            
        } else if (_markedForDisplay || updating) {
//            [KKGridView animateIf:_staggerForInsertion delay:(index + 1) * 0.0015 options:UIViewAnimationOptionBeginFromCurrentState block:^{
//                updateCellFrame(cell, indexPath);
//            }];
        }
        
        // Highlight cells updated in the model.
        cell.selected = [_selectedIndexPaths containsObject:indexPath];
        index++;
    }
    
    // Remove offscreen cells (recycle them)
    [self _cleanupCells];
}

// Layout all cells in the entire model. use for updates when a cell wouldn't be on screen mid-update

- (void)_layoutModelCells
{
    [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
        [_visibleCells enumerateKeysAndObjectsUsingBlock:^(KKIndexPath *keyPath, KKGridViewCell *cell, BOOL *stop) {
            cell.frame = [self rectForCellAtIndexPath:keyPath]; 
        }];
    }];
}

#pragma mark - Updates

// handles individual index path updates each run-loop.

- (KKGridViewAnimation)_handleUpdateForIndexPath:(KKIndexPath *)indexPath visibleIndexPaths:(NSArray *)visibleIndexPaths
{
    _needsAccessoryReload = YES;
    _markedForDisplay = YES;
    _staggerForInsertion = YES;
    
    KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
    KKGridViewAnimation animation = update.animation;
    
    if (update.type == KKGridViewUpdateTypeItemInsert || update.type == KKGridViewUpdateTypeItemDelete) {
        [self _incrementCellsAtIndexPath:indexPath
                             toIndexPath:[self _lastIndexPathForSection:indexPath.section]
                                byAmount:update.sign];
    }
    
    NSMutableSet *replacementSet = [[NSMutableSet alloc] initWithCapacity:[_selectedIndexPaths count]];
    
    for (KKIndexPath *keyPath in _selectedIndexPaths) {
        BOOL conditionMap[KKGridViewUpdateTypeSectionReload+1] = {
            [KKGridViewUpdateTypeItemInsert] = keyPath.index >= indexPath.index,
            [KKGridViewUpdateTypeItemDelete] = indexPath.index < keyPath.index && keyPath.index != 0
        };
        
        if (conditionMap[update.type] && indexPath.section == keyPath.section) {
            keyPath.index += update.sign;
        }
        
        [replacementSet addObject:keyPath];
    }
    
    [_selectedIndexPaths setSet:replacementSet];
    
    return animation;
}

#pragma mark - Metric Calculation

// Follow the math, young padawan!
// Reiteratively adds precalculated section heights up to x section.

- (CGFloat)_sectionHeightsCombinedUpToSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    for (NSUInteger index = 0; index < section && index < _metrics.count; index++) {
        height += _metrics.sections[index].sectionHeight;
    }
    return height;
}

- (CGFloat)_sectionHeightsCombinedUpToRow:(NSUInteger)row inSection:(NSUInteger)section
{
    CGFloat height = 0.f;
    for (NSUInteger index = 0; index < section && index < _metrics.count; index++) {
        height += _metrics.sections[index].sectionHeight;
    }
    
    for (NSUInteger index = 0; index < row; index++) {
        height += _metrics.sections[section].rowHeight;
    }
    return height;
}

#pragma mark - Cell Management

- (void)_displayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath withAnimation:(KKGridViewAnimation)animation
{
    if (_delegateRespondsTo.willDisplayCell) {
        [self.delegate gridView:self willDisplayCell:cell atIndexPath:indexPath];
    }
    
    if ([_updateStack hasUpdateForIndexPath:indexPath]) {
        KKGridViewUpdate *update = [_updateStack updateForIndexPath:indexPath];
        update.animating = YES;
    }
    
    switch (animation) {
        case KKGridViewAnimationNone: {
            break;
        }
        case KKGridViewAnimationFade: {
            cell.alpha = 0.f;
            break;
        }
        case KKGridViewAnimationExplode: {
            cell.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
            cell.alpha = 0.f;
            break;
        }   
        default:
            break;
    }
    
    if (cell.superview) {
        cell.hidden = NO;
        cell.alpha = 1.;
    } else {
        BOOL subviewIndex = _backgroundView ? _rowViews.count + 1 : _rowViews.count;
        [self insertSubview:cell atIndex:subviewIndex];
    }
    
    switch (animation) {
        case KKGridViewAnimationFade: {
            [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
                cell.alpha = 1.f;
            } completion:^(BOOL finished) {
                if ([_updateStack hasUpdateForIndexPath:indexPath])
                    [_updateStack removeUpdateForIndexPath:indexPath];
            }];
            break;
        }
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
    [[self _reusableCellSetForIdentifier:identifier] addObject:cell];
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
        set = [_reusableCells objectForKey:identifier];
    }
    return set;
}

#pragma mark - Internal IndexPath Getters

- (KKIndexPath *)_lastIndexPathForSection:(NSUInteger)section
{
    return [KKIndexPath indexPathForIndex:_metrics.sections[section].itemCount inSection:section];
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
    NSMutableArray *indexes = [[NSMutableArray alloc] initWithCapacity:visiblePaths.count];
    
    for (KKIndexPath *indexPath in visiblePaths) {
        CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, cellRect))
            [indexes addObject:indexPath];
        
    }
    
    return indexes;
}

- (KKIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    NSArray *indexes = [self indexPathsForItemsInRect:(CGRect){ point, {1.f, 1.f } }];
    return indexes.count > 0 ? [indexes objectAtIndex:0] : [KKIndexPath indexPathForIndex:NSNotFound inSection:NSNotFound];
}

- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath
{
    CGPoint point = { 
        _cellPadding.width,
        _cellPadding.height + _gridHeaderView.frame.size.height,
    };
    
    for (NSUInteger section = 0; section < indexPath.section; section++) {
        if (_metrics.count > section) {
            point.y += _metrics.sections[section].sectionHeight;
        }
    }
    
    if (indexPath.section < _metrics.count) {
        point.y += _metrics.sections[indexPath.section].headerHeight;
    }
    
    NSInteger row = indexPath.index / _numberOfColumns;
    NSInteger column = indexPath.index - (row * _numberOfColumns);
    
    point.y += (row * (_cellSize.height + _cellPadding.height));
    point.x += (column * (_cellSize.width + _cellPadding.width));

    if (indexPath.section == 1) {
        NSLog(@"%@", NSStringFromCGRect(CGRectIntegral((CGRect){point, _cellSize})));
    }
    
    return CGRectIntegral((CGRect){point, _cellSize});
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

- (NSArray *)visibleIndexPaths
{
    CGRect const visibleBounds = {self.contentOffset, self.bounds.size};
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:12];
    
    KKIndexPath *indexPath = [KKIndexPath zeroIndexPath];
    
    for (NSUInteger section = 0; section < _metrics.count; section++) {
        indexPath.section = section;
        
        for (NSUInteger index = 0; index < _metrics.sections[section].itemCount; index++) {
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

- (void)_incrementCellsAtIndexPath:(KKIndexPath *)fromPath toIndexPath:(KKIndexPath *)toPath byAmount:(NSInteger)amount
{
    NSMutableDictionary *replacement = [[NSMutableDictionary alloc] init];
    NSArray *allVisibleIndexPaths = [[_visibleCells allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    for (KKIndexPath *keyPath in allVisibleIndexPaths) {
        KKGridViewCell *originalCell = [_visibleCells objectForKey:keyPath];
        NSLog(@"%@", keyPath);
        KKIndexPath *originalIndexPath = [keyPath copy];
        
        NSUInteger amountForPath = amount;
        
        if (keyPath.section == fromPath.section) {
            NSComparisonResult pathComparison = [fromPath compare:keyPath];
            NSComparisonResult lastPathComparison = [[self _lastIndexPathForSection:fromPath.section] compare:keyPath];
            
            BOOL indexPathIsLessOrEqual = pathComparison == NSOrderedAscending || pathComparison == NSOrderedSame;
            BOOL lastPathIsGreatorOrEqual = lastPathComparison == NSOrderedDescending || lastPathComparison == NSOrderedSame;
            
            if (indexPathIsLessOrEqual && lastPathIsGreatorOrEqual && amount < 0 && pathComparison == NSOrderedSame) {
                
                [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
                    originalCell.alpha = 0.f;
                } completion:^(BOOL finished) {
                    originalCell.hidden = YES;
                }];
            }
            if (!indexPathIsLessOrEqual || !lastPathIsGreatorOrEqual) {
                amountForPath = 0;
            }
        } else if (keyPath.section > toPath.section) {
            amountForPath = 0;
        }
        
        keyPath.index+= amount;
        
        if ([keyPath isEqual:originalIndexPath]) {
            [replacement setObject:originalCell forKey:keyPath];
        } else {
            KKGridViewCell *cell = [_dataSource gridView:self cellForItemAtIndexPath:keyPath];
            cell.frame = originalCell.frame;
            [self _displayCell:cell atIndexPath:originalIndexPath withAnimation:KKGridViewAnimationFade];

            [originalCell removeFromSuperview];

            [replacement setObject:cell forKey:keyPath];

            [UIView animateWithDuration:0.5f animations:^{
                cell.frame = [self rectForCellAtIndexPath:keyPath];
            }];
        }
    }


    [_visibleCells setDictionary:replacement];
}

#pragma mark - Item Editing

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    
    for (KKIndexPath *indexPath in [indexPaths sortedArrayUsingSelector:@selector(compare:)])
        [_updateStack addUpdate:[KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemInsert animation:animation]];
    
    if (!_batchUpdating) {
        [self _reloadMetrics];
        [self _layoutGridView];
    }
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation
{
    [self _reloadMetrics];
    
    for (KKIndexPath *indexPath in [indexPaths sortedArrayUsingSelector:@selector(compare:)]) {
        KKGridViewUpdate *update = [KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemDelete animation:animation];
        [_updateStack addUpdate:update];
    }
    
    _staggerForInsertion = YES;
    _markedForDisplay = YES;
    [self _layoutGridView];
    [self _performRemainingUpdatesModelOnly];
}

- (void)moveItemAtIndexPath:(KKIndexPath *)indexPath toIndexPath:(KKIndexPath *)newIndexPath
{
    [self _reloadMetrics];
    @throw [NSException exceptionWithName:@"Operation Not Implemented" 
                                   reason:@"KKGridViewUpdateTypeItemMove is not yet implemented. Sorry!"
                                 userInfo:nil];
    //    
    //    
    //    KKGridViewUpdate *update = [KKGridViewUpdate updateWithIndexPath:indexPath isSectionUpdate:NO type:KKGridViewUpdateTypeItemMove animation:KKGridViewAnimationNone];
    //    update.destinationPath = newIndexPath;
    //    [_updateStack addUpdate:update];
    //    
    //    _staggerForInsertion = YES;
    //    _markedForDisplay = YES;
    //    [self _layoutGridView];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    for (KKIndexPath *path in indexPaths) {
        KKGridViewCell *cell = [_visibleCells objectForKey:path];
        if (cell) {
            cell.hidden = YES;
            cell.alpha = 0.;
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
    
    void (^clearViewsInArray)(NSMutableArray *) = ^(NSMutableArray *views) {
        for (id view in [views valueForKey:@"view"]) {
            if (view != [NSNull null])
                [view removeFromSuperview];
        }
        
        [views removeAllObjects];
    };
    
    if (_dataSourceRespondsTo.viewForHeader || _dataSourceRespondsTo.titleForHeader) {
        clearViewsInArray(_headerViews);
        if (!_headerViews)
        {
            _headerViews = [[NSMutableArray alloc] initWithCapacity:_metrics.count];
        }
        
        for (NSUInteger section = 0; section < _metrics.count; section++) {
            UIView *view = [self _viewForHeaderInSection:section];
            KKGridViewHeader *header = [[KKGridViewHeader alloc] initWithView:view];
            [_headerViews addObject:header];
            
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section] + _gridHeaderView.frame.size.height;
            [self _configureSectionView:header inSection:section withStickPoint:position height:_metrics.sections[section].headerHeight];
            
            [self addSubview:header.view];
        }
    }
    
    if (_dataSourceRespondsTo.viewForRow) {
        clearViewsInArray(_rowViews);
        if (!_rowViews)
        {
            _rowViews = [[NSMutableArray alloc] initWithCapacity:_metrics.count];
        }
        
        for (NSUInteger section = 0; section < _metrics.count; section++) {
            NSInteger previouslyCheckedRow = -1;
            
            for (NSUInteger index = 0; index < _metrics.sections[section].itemCount; index++) {
                NSInteger row = index / _numberOfColumns;
                
                if (row <= previouslyCheckedRow)
                    continue;
                
                previouslyCheckedRow = row;
                
                UIView *view = [_dataSource gridView:self viewForRow:row inSection:section];
                if (!view) {
                    continue;
                }
                
                KKGridViewRowBackground *rowBackground = [[KKGridViewRowBackground alloc] initWithView:view];
                [_rowViews addObject:rowBackground];
                
                CGFloat rowHeight = _cellSize.height + _cellPadding.height;
                CGFloat position = [self _sectionHeightsCombinedUpToRow:row inSection:section] + _gridHeaderView.frame.size.height;
                [self _configureSectionView:rowBackground inSection:section withStickPoint:position height:rowHeight];
                
                if (_backgroundView)
                    [self insertSubview:rowBackground.view aboveSubview:_backgroundView];
                else
                    [self insertSubview:rowBackground.view atIndex:0];
            }
        }
    }
    
    if (_dataSourceRespondsTo.viewForFooter || _dataSourceRespondsTo.titleForFooter) {
        clearViewsInArray(_footerViews);
        if (!_footerViews)
        {
            _footerViews = [[NSMutableArray alloc] initWithCapacity:_metrics.count];
        }
        
        for (NSUInteger section = 0; section < _metrics.count; section++) {
            UIView *view = [self _viewForFooterInSection:section];
            KKGridViewFooter *footer = [[KKGridViewFooter alloc] initWithView:view];
            [_footerViews addObject:footer];
            
            CGFloat footerHeight = _metrics.sections[section].footerHeight;
            CGFloat position = [self _sectionHeightsCombinedUpToSection:section+1] + _gridHeaderView.frame.size.height - footerHeight;
            [self _configureSectionView:footer inSection:section withStickPoint:position height:footerHeight];
            
            [self addSubview:footer.view];
        }
    }
    
    // IndexView
    if (_dataSourceRespondsTo.sectionIndexTitles) {
        [_indexView removeFromSuperview];
        
        NSArray *indexes = [_dataSource sectionIndexTitlesForGridView:self];
        if ([indexes isKindOfClass:[NSArray class]] && [indexes count]) {
            if (!_indexView)
                _indexView = [[KKGridViewIndexView alloc] initWithFrame:CGRectZero];
            
            _indexView.sectionIndexTitles = indexes;
            
            __kk_weak KKGridView *weakSelf = self;
            [_indexView setSectionTracked:^(NSUInteger section) {
                KKGridView *strongSelf = weakSelf;
                
                NSUInteger sectionToScroll = section;
                if (strongSelf->_dataSourceRespondsTo.sectionForSectionIndexTitle)
                    sectionToScroll = [strongSelf->_dataSource gridView:strongSelf
                                            sectionForSectionIndexTitle:[indexes objectAtIndex:section] 
                                                                atIndex:section];
                
                [strongSelf scrollToItemAtIndexPath:[KKIndexPath indexPathForIndex:0 inSection:sectionToScroll]
                                           animated:NO
                                           position:KKGridViewScrollPositionTop]; 
            }];
            
            [self _insertSubviewBelowScrollbar:_indexView];
        }
    }
}

- (void)reloadData
{
    NSAssert([NSThread isMainThread],@"-[KKGridView reloadData] must be sent from the main thread.");
    
    [self _commonReload];
    // cells are saved in _reusableCells container to re-use them later on
    for (KKGridViewCell *cell in [_visibleCells allValues]) {
        [[self _reusableCellSetForIdentifier:cell.reuseIdentifier] addObject:cell];
        cell.hidden = YES;
        cell.alpha = 0.f;
    }
    
    [_visibleCells removeAllObjects];
    [self setNeedsLayout];
}

- (void)_softReload
{
    [self _commonReload];
    
    [self _layoutModelCells];
    [self _cleanupCells];
}

- (void)reloadContentSize
{
    [self _reloadMetrics];
    
    NSUInteger oldColumns = _numberOfColumns;
    _numberOfColumns = self.bounds.size.width / (_cellSize.width + _cellPadding.width);
    
    if (oldColumns != _numberOfColumns) {
        _markedForDisplay = YES;
    }
    
    CGSize newContentSize = {
        self.bounds.size.width,
        _gridHeaderView.frame.size.height + _gridFooterView.frame.size.height
    };
    
    for (NSUInteger i = 0; i < _metrics.count; ++i) {
        CGFloat heightForSection = 0.f;
        
        struct KKSectionMetrics sectionMetrics = _metrics.sections[i];
        _metrics.sections[i].rowHeight = (_cellSize.height + _cellPadding.height);
        
        heightForSection += sectionMetrics.headerHeight + sectionMetrics.footerHeight;
        
        NSUInteger numberOfRows = ceilf(sectionMetrics.itemCount / (float)_numberOfColumns);
        heightForSection += numberOfRows * _metrics.sections[i].rowHeight;
        heightForSection += (numberOfRows? _cellPadding.height:0.f);
        
        _metrics.sections[i].sectionHeight = heightForSection;
        newContentSize.height += heightForSection;
    }
    
    self.contentSize = newContentSize;
}

- (void)_reloadMetrics
{
    NSUInteger numberOfSections = _dataSourceRespondsTo.numberOfSections ? [_dataSource numberOfSectionsInGridView:self] : 1;
    
    // If the _metrics.sections array has the right number of items in it,
    // then we can edit it in place (and don't need to allocate a new array 
    // each time. If it is not the right size, then we'll wipe it out and 
    // start over.
    BOOL arrayIsCorrectSize = _metrics.count == numberOfSections;
    
    struct KKSectionMetrics *metricsArray = _metrics.sections;
    
    if (!arrayIsCorrectSize)
    {
        [self _cleanupMetrics];
        metricsArray = calloc(numberOfSections, sizeof(struct KKSectionMetrics));
    }
    
    
    NSUInteger index;
    for (index = 0; index < numberOfSections; ++index)
    {
        BOOL willDrawHeader = _dataSourceRespondsTo.viewForHeader || _dataSourceRespondsTo.titleForHeader;
        BOOL willDrawFooter = _dataSourceRespondsTo.viewForFooter || _dataSourceRespondsTo.titleForFooter;
        
        struct KKSectionMetrics sectionMetrics = { 
            .footerHeight = willDrawFooter ? 24.0 : 0.0,
            .headerHeight = willDrawHeader ? 24.0 : 0.0,
            .sectionHeight = 0.f,
            .itemCount = [_dataSource gridView:self numberOfItemsInSection:index]
        };
        
        if (_dataSourceRespondsTo.heightForHeader)
            sectionMetrics.headerHeight = [_dataSource gridView:self heightForHeaderInSection:index];
        if (_dataSourceRespondsTo.heightForFooter)
            sectionMetrics.footerHeight = [_dataSource gridView:self heightForFooterInSection:index];
        
        metricsArray[index] = sectionMetrics;
    }
    
    if (!arrayIsCorrectSize)
        _metrics = (struct KKMetricsArray){ metricsArray, index };    
}

- (void)_cleanupMetrics
{
    if (_metrics.sections)
        free(_metrics.sections);
    
    _metrics = (struct KKMetricsArray){ NULL, 0 };
}

#pragma mark - Header and Footer Views

- (UIView *)_viewForHeaderInSection:(NSUInteger)section
{
    NSAssert(_dataSourceRespondsTo.viewForHeader || _dataSourceRespondsTo.titleForHeader, @"DataSource must provide title or view for header.");
    
    UIView *headerView = nil;
    
    if (_dataSourceRespondsTo.viewForHeader) {
        headerView = [_dataSource gridView:self viewForHeaderInSection:section];
    }
    
    if (!headerView && _dataSourceRespondsTo.titleForHeader) {
        KKGridViewSectionLabel *label = [[KKGridViewSectionLabel alloc] initWithString:[_dataSource gridView:self titleForHeaderInSection:section]];
        headerView = label;
    }
    
    return headerView;
}

- (UIView *)_viewForFooterInSection:(NSUInteger)section
{
    NSAssert(_dataSourceRespondsTo.viewForFooter || _dataSourceRespondsTo.titleForFooter, @"DataSource must provide title or view for footer.");
    
    UIView *footerView = nil;
    
    if (_dataSourceRespondsTo.viewForFooter) {
        footerView = [_dataSource gridView:self viewForFooterInSection:section];
    }
    
    if (!footerView && _dataSourceRespondsTo.titleForFooter) {
        KKGridViewSectionLabel *label = [[KKGridViewSectionLabel alloc] initWithString:[_dataSource gridView:self titleForFooterInSection:section]];
        footerView = label;
    }
    
    return footerView;
}

#pragma mark - Subviewinsertion

- (void)_insertSubviewBelowScrollbar:(UIView *)view {
    if (_indexView && view != _indexView)
        [self insertSubview:view belowSubview:_indexView];
    else
        [self insertSubview:view atIndex:self.subviews.count - 1];
}

#pragma mark - Positioning

- (void)scrollToItemAtIndexPath:(KKIndexPath *)indexPath animated:(BOOL)animated position:(KKGridViewScrollPosition)scrollPosition
{
    CGRect cellRect = [self rectForCellAtIndexPath:indexPath];
    if (scrollPosition == KKGridViewScrollPositionNone) {
        [self scrollRectToVisible:cellRect animated:animated];
        return;
    }
    
    CGFloat boundsHeight = self.bounds.size.height - self.contentInset.bottom;
    CGFloat headerPlusPadding = _metrics.sections[indexPath.section].headerHeight + self.cellPadding.height;
    
    [KKGridView animateIf:animated duration:0.3 delay:0.f options:0 block:^{
        CGFloat const offsetMap[] = {
            [KKGridViewScrollPositionTop] = CGRectGetMinY(cellRect) + self.contentInset.top - headerPlusPadding,
            [KKGridViewScrollPositionBottom] = CGRectGetMaxY(cellRect) - boundsHeight + headerPlusPadding,
            [KKGridViewScrollPositionMiddle] = CGRectGetMaxY(cellRect) - (boundsHeight / 2)
        };
        
        self.contentOffset = (CGPoint) {.y = offsetMap[scrollPosition]};
    }];
}

#pragma mark - Public Selection Methods

- (void)selectItemsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated
{
    if (!indexPaths)
        return;
    
    [KKGridView animateIf:animated delay:0.f options:0 block:^{
        for (KKIndexPath *indexPath in indexPaths) {
            [self _selectItemAtIndexPath:indexPath];
        }
    }];
}

- (void)deselectItemsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated
{
    if (!indexPaths)
        return;
    
    [KKGridView animateIf:animated delay:0.f options:0 block:^{
        for (KKIndexPath *indexPath in indexPaths) {
            [self _deselectItemAtIndexPath:indexPath];
        }
    }];
}

- (void)deselectAll:(BOOL)animated
{
    [KKGridView animateIf:animated delay:0.f options:0 block:^{
        [self _deselectAll];
    }];
}

- (KKIndexPath*)indexPathForSelectedCell
{
    return !_allowsMultipleSelection ? _selectedIndexPaths.anyObject : nil;
}

- (NSArray *)indexPathsForSelectedCells
{
    return [_selectedIndexPaths allObjects];
}

#pragma mark - Internal Selection Methods

- (void)_highlightItemAtIndexPath:(KKIndexPath *)indexPath
{
    [self _cancelHighlighting];
    
    _highlightedIndexPath = indexPath;
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    cell.highlighted = YES;
}

- (void)_cancelHighlighting
{
    if (!_highlightedIndexPath)
        return;
    
    KKGridViewCell *cell = [_visibleCells objectForKey:_highlightedIndexPath];
    cell.highlighted = NO;
    
    _highlightedIndexPath = nil;
}

- (void)_selectItemAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    
    [self _cancelHighlighting];
    
    if (_allowsMultipleSelection) {
        if ([_selectedIndexPaths containsObject:indexPath]) {
            [self _deselectItemAtIndexPath:indexPath];
            return;
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
    
    if (_delegateRespondsTo.didSelectItem) {
        [self.delegate gridView:self didSelectItemAtIndexPath:indexPath];
    }
}


- (void)_deselectAll
{
    for (KKIndexPath* indexPath in _selectedIndexPaths)
    {
        KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
        cell.selected = NO;
        
        if(_delegateRespondsTo.willDeselectItem)
        {
            [self.delegate gridView:self willDeselectItemAtIndexPath:indexPath];
        }
    }
    
    [_selectedIndexPaths removeAllObjects];
}

- (void)_deselectItemAtIndexPath:(KKIndexPath *)indexPath
{
    if (_selectedIndexPaths.count > 0 && _delegateRespondsTo.willDeselectItem && indexPath.index != NSNotFound && indexPath.section != NSNotFound) {
        KKIndexPath *redirectedPath = [self.delegate gridView:self willDeselectItemAtIndexPath:indexPath];
        if (redirectedPath != nil && ![redirectedPath isEqual:indexPath]) {
            indexPath = redirectedPath;
        }
    }
    
    KKGridViewCell *cell = [_visibleCells objectForKey:indexPath];
    if ([_selectedIndexPaths containsObject:indexPath]) {
        [_selectedIndexPaths removeObject:indexPath];
        cell.selected = NO;
    }
    
    if (_delegateRespondsTo.didDeselectItem) {
        [self.delegate gridView:self didDeselectItemAtIndexPath:indexPath];
    }
}

#pragma mark - Touch Handling

- (void)_handleSelection:(UILongPressGestureRecognizer *)recognizer
{
    UIGestureRecognizerState state = recognizer.state;
    CGPoint locationInSelf = [recognizer locationInView:self];
    
    if (_indexView) {
        if (state == UIGestureRecognizerStateBegan && CGRectContainsPoint(_indexView.frame, locationInSelf)) {
            self.scrollEnabled = NO;
            [_indexView setTracking:YES location:[recognizer locationInView:_indexView]];
            return;
        }
        else if (state == UIGestureRecognizerStateChanged && _indexView.tracking) {
            [_indexView setTracking:YES location:CGPointMake(0.0, [recognizer locationInView:_indexView].y)];
            return;
        }
        else if ((state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) && _indexView.tracking) {
            self.scrollEnabled = YES;
            [_indexView setTracking:NO location:[recognizer locationInView:_indexView]];
            return;
        }
    }
    
    if ([self isDecelerating])
        return;
    
    KKIndexPath *indexPath = [self indexPathForItemAtPoint:locationInSelf];
    
    // The index path may be invalid, for example if the touch point falls outside
    // of the grid. In that case we abort further processing, as it only makes sense
    // with a valid grid cell being selected.
    if (!indexPath || indexPath.index == NSNotFound || indexPath.section == NSNotFound) {
        [self _cancelHighlighting];
        return;
    }
    
    if (state == UIGestureRecognizerStateEnded && _delegateRespondsTo.willSelectItem && ![self isDragging])
        indexPath = [self.delegate gridView:self willSelectItemAtIndexPath:indexPath];
    
    // The delegate may have returned a nil index path to cancel the selection.
    if (!indexPath) {
        [self _cancelHighlighting];
        return;
    }
    
    if (state == UIGestureRecognizerStateBegan) {
        [self _highlightItemAtIndexPath:indexPath];
    }
    
    else if (state == UIGestureRecognizerStateEnded) {
        BOOL touchInSameCell = CGRectContainsPoint([self rectForCellAtIndexPath:_highlightedIndexPath], locationInSelf);
        if (touchInSameCell && ![self isDragging])
            [self _selectItemAtIndexPath:indexPath];
        [self _cancelHighlighting];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return (gestureRecognizer == _selectionRecognizer || otherGestureRecognizer == _selectionRecognizer);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        _indexView.frame = (CGRect) {
            {_indexView.frame.origin.x, self.contentOffset.y},
            _indexView.frame.size
        };
        [self _cancelHighlighting];
    }
    
    else if ([keyPath isEqualToString:@"tracking"]) {
        if (self.tracking && !self.dragging) {
            [self _cancelHighlighting];
        }
    }
}

#pragma mark - Animation Helpers

+ (void)animateIf:(BOOL)animated duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options block:(void(^)())block
{
    if (animated)
        [UIView animateWithDuration:duration delay:delay options:options animations:block completion:nil];
    else
        block();
}

+ (void)animateIf:(BOOL)animated delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options block:(void(^)())block
{
    [self animateIf:animated duration:KKGridViewDefaultAnimationDuration delay:delay options:options block:block];
}

#pragma mark - Cleanup

- (void)dealloc
{
    [super setDelegate:nil];
    [self removeObserver:self forKeyPath:@"contentOffset"];
    [self removeObserver:self forKeyPath:@"tracking"];
    [self removeGestureRecognizer:_selectionRecognizer];
    [self _cleanupMetrics];
}

@end

