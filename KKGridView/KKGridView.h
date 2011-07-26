//
//  KKGridView.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewCell.h"
#import "KKIndexPath.h"

@protocol KKGridViewDataSource, KKGridViewDelegate;

@interface KKGridView : UIScrollView {
    @private
    CGSize _cellPadding;
    CGSize _cellSize;
    id <KKGridViewDataSource> _dataSource;
    struct {
        unsigned  dataSourceRespondsToHeightForFooterInSection:1;
        unsigned  dataSourceRespondsToHeightForHeaderInSection:1;
        unsigned  dataSourceRespondsToNumberOfSections:1;
        unsigned  delegateRespondsToDidSelectItem:1;
    } _flags;
    id <KKGridViewDelegate> _gridDelegate;
    UIView *_gridFooterView;
    UIView *_gridHeaderView;
    NSUInteger _numberOfColumns;
    NSUInteger _numberOfItems;
    NSUInteger _numberOfSections;
    NSMutableDictionary * _reusableCells;
    NSMutableDictionary * _visibleCells;
}

#pragma mark - Properties

@property (nonatomic) CGSize cellPadding;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, assign) id <KKGridViewDataSource> dataSource;
@property (nonatomic, assign) id <KKGridViewDelegate> gridDelegate;
@property (nonatomic, retain) UIView *gridFooterView;
@property (nonatomic, retain) UIView *gridHeaderView;
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;

#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame dataSource:(id <KKGridViewDataSource>)dataSource delegate:(id <KKGridViewDelegate>)delegate;

#pragma mark - Getters

- (KKGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (CGRect)rectForCellAtIndexPath:(KKIndexPath *)indexPath;
- (NSIndexSet *)visibleIndices;

#pragma mark - Methods

- (void)reloadContentSize;
- (void)reloadData;

@end

#pragma mark - KKGridViewDataSource

@protocol KKGridViewDataSource <NSObject>

@required

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section;
//- (NSUInteger)numberOfColumnsInGridView:(KKGridView *)gridView;
- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForRowAtIndexPath:(KKIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView;
- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section;

@end

#pragma mark - KKGridViewDelegate

@protocol KKGridViewDelegate <NSObject>

- (void)gridView:(KKGridView *)gridView didSelectItemIndexPath:(NSIndexPath *)indexPath;

@end
