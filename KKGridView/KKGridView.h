//
//  KKGridView.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 contributors. All rights reserved.
//

#import "KKGridViewCell.h"

@protocol KKGridViewDataSource, KKGridViewDelegate;

@interface KKGridView : UIScrollView {
    @private
    id <KKGridViewDataSource> _dataSource;
    id <KKGridViewDelegate> _gridDelegate;
}

@property (nonatomic, assign) id <KKGridViewDataSource> dataSource;
@property (nonatomic, assign) id <KKGridViewDelegate> gridDelegate;

#pragma mark - Properties

#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame dataSource:(id <KKGridViewDataSource>)dataSource delegate:(id <KKGridViewDelegate>)delegate;

@end

#pragma mark - KKGridViewDataSource

@protocol KKGridViewDataSource <NSObject>

@required

- (NSUInteger)gridView:(KKGridView *)gridView numberOfRowsInSection:(NSUInteger)section;
- (KKGridViewCell *)gridView:(UITableView *)gridView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView;

@end

#pragma mark - KKGridViewDelegate

@protocol KKGridViewDelegate <NSObject>

- (void)gridView:(KKGridView *)gridView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end