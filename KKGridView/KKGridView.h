//
//  KKGridView.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewCell.h"
#import "Definitions.h"
#import "KKIndexPath.h"
#import "KKGridViewViewInfo.h"

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

@protocol KKGridViewDataSource, KKGridViewDelegate;

@interface KKGridView : UIScrollView

#pragma mark - Properties

@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic) CGSize cellPadding;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, __kk_weak) id <KKGridViewDataSource> dataSource;
@property (nonatomic, __kk_weak) id <KKGridViewDelegate> gridDelegate;
@property (nonatomic, strong) UIView *gridFooterView;
@property (nonatomic, strong) UIView *gridHeaderView;
@property (nonatomic, readonly) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;


#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame dataSource:(id <KKGridViewDataSource>)dataSource delegate:(id <KKGridViewDelegate>)delegate;

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath;
- (NSArray *)visibleIndexPaths;

#pragma mark - Data

- (void)reloadContentSize;
- (void)reloadData;
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation;
//- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withAnimation:(KKGridViewAnimation)animation;
//- (void)insertSections:(NSIndexSet *)sections withItemAnimation:(KKGridViewAnimation)animation;
//- (void)deleteSections:(NSIndexSet *)sections withItemAnimation:(KKGridViewAnimation)animation;
//- (void)reloadSections:(NSIndexSet *)sections withAnimation:(KKGridViewAnimation)animation;

@end

#pragma mark - KKGridViewDataSource

@class KKGridViewHeader;

@protocol KKGridViewDataSource <NSObject>

@required

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section;
//- (NSUInteger)numberOfColumnsInGridView:(KKGridView *)gridView;
- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView;
- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section;
- (UIView *)gridView:(KKGridView *)gridView viewForFooterInSection:(NSUInteger)section;

@end

#pragma mark - KKGridViewDelegate

@protocol KKGridViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (void)gridView:(KKGridView *)gridView didSelectItemIndexPath:(KKIndexPath *)indexPath;

@end
