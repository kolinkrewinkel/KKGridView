//
//  KKGridView.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewCell.h"
#import "KKIndexPath.h"
#import "KKGridViewHeader.h"

@protocol KKGridViewDataSource, KKGridViewDelegate;

@interface KKGridView : UIScrollView

#pragma mark - Properties

@property (nonatomic) BOOL allowsMultipleSelection;
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
- (NSArray *)visibleIndexPaths;

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
- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section;

@end

#pragma mark - KKGridViewDelegate

@protocol KKGridViewDelegate <NSObject>

@optional

- (void)gridView:(KKGridView *)gridView didSelectItemIndexPath:(KKIndexPath *)indexPath;

@end
