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
    self.view = _gridView;
}

@end
