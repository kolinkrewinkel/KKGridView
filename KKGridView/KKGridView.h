//
//  KKGridView.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewCell.h"

@protocol KKGridViewDataSource, KKGridViewDelegate;

@interface KKGridView : UIScrollView {
    @private
    CGSize _cellPadding;
    CGSize _cellSize;
    id <KKGridViewDataSource> _dataSource;
    id <KKGridViewDelegate> _gridDelegate;
    UIView *_gridFooterView;
    UIView *_gridHeaderView;
    NSUInteger _numberOfColumns;
    NSUInteger _numberOfSections;
    NSMutableSet * _reusableCells;
    NSMutableSet * _visibleCells;
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

- (CGRect)rectForCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexSet *)visibleIndices;

#pragma mark - Methods

- (void)reloadContentSize;
- (void)reloadData;

@end

#pragma mark - KKGridViewDataSource

@protocol KKGridViewDataSource <NSObject>

@required

- (NSUInteger)gridView:(KKGridView *)gridView numberOfRowsInSection:(NSUInteger)section;
- (KKGridViewCell *)gridView:(UITableView *)gridView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView;
- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section;

@end

#pragma mark - KKGridViewDelegate

@protocol KKGridViewDelegate <NSObject>

- (void)gridView:(KKGridView *)gridView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end