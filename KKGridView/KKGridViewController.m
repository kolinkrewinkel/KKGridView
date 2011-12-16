//
//  KKGridViewController.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 10.22.11.
//  Copyright (c) 2011 Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewController.h"

@implementation KKGridViewController
@synthesize gridView = _gridView;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    _gridView = [[KKGridView alloc] initWithFrame:self.view.bounds];
    _gridView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _gridView.dataSource = self;
    _gridView.gridDelegate = self;
    self.view = _gridView;
}

#pragma mark - KKGridViewDataSource

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    return 0;
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{
    return [KKGridViewCell cellForGridView:gridView];
}

@end
