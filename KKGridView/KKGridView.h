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

@protocol KKGridViewDataSource;

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

#pragma mark - Data Source and Delegate
@property (nonatomic, __kk_weak) id <KKGridViewDataSource> dataSource;

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


@protocol KKGridViewDataSource <NSObject>
@required
- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section;
- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath;
@optional
- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView;
- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForFooterInSection:(NSUInteger)section;
@end