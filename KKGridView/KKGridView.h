//
//  KKGridView.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewCell.h>
#import <KKGridView/KKIndexPath.h>
#import <KKGridView/Definitions.h>

typedef enum {
    KKGridViewAnimationFade,
    KKGridViewAnimationResize,
    KKGridViewAnimationSlideLeft,
    KKGridViewAnimationSlideTop,
    KKGridViewAnimationSlideRight,
    KKGridViewAnimationSlideBottom,
    KKGridViewAnimationExplode,
    KKGridViewAnimationImplode,
    KKGridViewAnimationNone
} KKGridViewAnimation;

typedef enum {
    KKGridViewLayoutDirectionVertical,
    KKGridViewLayoutDirectionHorizontal
} KKGridViewLayoutDirection;

typedef enum {
    KKGridViewScrollPositionNone,        
    KKGridViewScrollPositionTop,    
    KKGridViewScrollPositionMiddle,   
    KKGridViewScrollPositionBottom
} KKGridViewScrollPosition;

@class KKGridView;

@protocol KKGridViewDataSource <NSObject>
@required
- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section;
- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath;
@optional
- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView;
- (NSString *)gridView:(KKGridView *)gridView titleForHeaderInSection:(NSUInteger)section;
- (NSString *)gridView:(KKGridView *)gridView titleForFooterInSection:(NSUInteger)section;
- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForFooterInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForRow:(NSUInteger)row inSection:(NSUInteger)section; // a row is compromised of however many cells fit in a column of a given section
- (NSArray *)sectionIndexTitlesForGridView:(KKGridView *)gridView;
- (NSInteger)gridView:(KKGridView *)gridView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
@end

@protocol KKGridViewDelegate <NSObject, UIScrollViewDelegate>
@optional
- (void)gridView:(KKGridView *)gridView didSelectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)gridView:(KKGridView *)gridView didDeselectItemAtIndexPath:(KKIndexPath *)indexPath;
- (KKIndexPath *)gridView:(KKGridView *)gridView willSelectItemAtIndexPath:(KKIndexPath *)indexPath;
- (KKIndexPath *)gridView:(KKGridView *)gridView willDeselectItemAtIndexPath:(KKIndexPath *)indexPath;
- (void)gridView:(KKGridView *)gridView willDisplayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath;
@end

@interface KKGridView : UIScrollView

#pragma mark - Properties

@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic) CGSize cellPadding;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, strong) UIView *gridFooterView;
@property (nonatomic, strong) UIView *gridHeaderView;
@property (nonatomic) KKGridViewLayoutDirection layoutDirection;
@property (nonatomic, readonly) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;
@property (nonatomic, readonly) BOOL batchUpdating;

#pragma mark - Data Source and Delegate
@property (nonatomic, kk_weak) IBOutlet id <KKGridViewDataSource> dataSource;
@property (nonatomic, assign)  IBOutlet id <KKGridViewDelegate> delegate;

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath;
- (NSArray *)visibleIndexPaths;

- (KKIndexPath *)indexPathForCell:(KKGridViewCell *)cell;
- (KKIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSArray *)indexPathsForItemsInRect:(CGRect)rect;

#pragma mark - Reloading

- (void)reloadContentSize;
- (void)reloadData;

#pragma mark - Editing

- (void)beginUpdates;
- (void)endUpdates;

#pragma mark Individual Items

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation;
//- (void)moveItemAtIndexPath:(KKIndexPath *)indexPath toIndexPath:(KKIndexPath *)newIndexPath;
- (void)scrollToItemAtIndexPath:(KKIndexPath *)indexPath animated:(BOOL)animated position:(KKGridViewScrollPosition)scrollPosition;

#pragma mark - Unimplemented

//- (void)insertSections:(NSIndexSet *)sections withItemAnimation:(KKGridViewAnimation)animation;
//- (void)deleteSections:(NSIndexSet *)sections withItemAnimation:(KKGridViewAnimation)animation;
//- (void)reloadSections:(NSIndexSet *)sections withAnimation:(KKGridViewAnimation)animation;

#pragma mark - Selection

- (void)selectItemsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated;
- (void)deselectItemsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated;
- (void)deselectAll: (BOOL)animated;
- (NSUInteger)selectedItemCount;

- (KKIndexPath *)indexPathForSelectedCell;
- (NSArray *)indexPathsForSelectedCells;

@end
