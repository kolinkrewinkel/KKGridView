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

typedef KKGridViewCell * (^KKGridViewCellForItemAtIndexPath)(KKGridView *gridView, KKIndexPath *indexPath);
typedef NSUInteger (^KKGridViewNumberOfSections)(KKGridView *gridView);
typedef NSUInteger (^KKGridViewNumberOfItemsInSection)(KKGridView *gridView, NSUInteger section);
typedef CGFloat (^KKGridViewHeightForHeaderInSection)(KKGridView *gridView, NSUInteger section);
typedef CGFloat (^KKGridViewHeightForFooterInSection)(KKGridView *gridView, NSUInteger section);
typedef UIView * (^KKGridViewViewForHeaderInSection)(KKGridView *gridView, NSUInteger section);
typedef UIView * (^KKGridViewViewForFooterInSection)(KKGridView *gridView, NSUInteger section);
typedef void (^KKGridViewIndexPath)(KKGridView *gridView, KKIndexPath *indexPath);
typedef KKIndexPath * (^KKGridViewReturnPath)(KKGridView *gridView, KKIndexPath *indexPath);
typedef void (^KKGridViewWillDisplayCellAtPath)(KKGridView *gridView, KKGridViewCell *cell, KKIndexPath *indexPath);

typedef enum {
    KKGridViewScrollPositionNone,        
    KKGridViewScrollPositionTop,    
    KKGridViewScrollPositionMiddle,   
    KKGridViewScrollPositionBottom
} KKGridViewScrollPosition;

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

@interface KKGridView : UIScrollView

#pragma mark - Properties

@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic) CGSize cellPadding;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, strong) UIView *gridFooterView;
@property (nonatomic, strong) UIView *gridHeaderView;
@property (nonatomic, readonly) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;

#pragma mark - Data Source

@property (nonatomic, copy) KKGridViewCellForItemAtIndexPath cellBlock;
@property (nonatomic, copy) KKGridViewNumberOfSections numberOfSectionsBlock;
@property (nonatomic, copy) KKGridViewNumberOfItemsInSection numberOfItemsInSectionBlock;
@property (nonatomic, copy) KKGridViewHeightForHeaderInSection heightForHeaderInSectionBlock;
@property (nonatomic, copy) KKGridViewHeightForFooterInSection heightForFooterInSectionBlock;
@property (nonatomic, copy) KKGridViewViewForHeaderInSection viewForHeaderInSectionBlock;
@property (nonatomic, copy) KKGridViewViewForFooterInSection viewForFooterInSectionBlock;

#pragma mark - Delegate

@property (nonatomic, copy) KKGridViewIndexPath didSelectIndexPathBlock;
@property (nonatomic, copy) KKGridViewReturnPath willSelectItemAtIndexPathBlock;
@property (nonatomic, copy) KKGridViewReturnPath willDeselectItemAtIndexPathBlock;
@property (nonatomic, copy) KKGridViewIndexPath didDeselectIndexPathBlock;
@property (nonatomic, copy) KKGridViewWillDisplayCellAtPath willDisplayCellAtPathBlock;

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath;
- (NSArray *)visibleIndexPaths;

#pragma mark - Reloading

- (void)reloadContentSize;
- (void)reloadData;

#pragma mark - Items

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation;
- (void)moveItemAtIndexPath:(KKIndexPath *)indexPath toIndexPath:(KKIndexPath *)newIndexPath;
- (void)scrollToItemAtIndexPath:(KKIndexPath *)indexPath animated:(BOOL)animated position:(KKGridViewScrollPosition)scrollPosition;

#pragma mark - Unimplemented

//- (void)insertSections:(NSIndexSet *)sections withItemAnimation:(KKGridViewAnimation)animation;
//- (void)deleteSections:(NSIndexSet *)sections withItemAnimation:(KKGridViewAnimation)animation;
//- (void)reloadSections:(NSIndexSet *)sections withAnimation:(KKGridViewAnimation)animation;


#pragma mark - Selection

- (void)selectRowsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated;
- (void)deselectRowsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated;

- (KKIndexPath*) indexPathForSelectedCell;
- (NSArray *)indexPathsForSelectedCells;

@end

