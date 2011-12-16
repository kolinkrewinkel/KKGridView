//
//  GridViewDemoViewController.h
//  GridViewDemo
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewController.h>

@interface GridViewDemoViewController : KKGridViewController <UISearchBarDelegate>

@property (nonatomic) NSUInteger firstSectionCount;
@property (nonatomic, strong) NSMutableArray *footerViews;
@property (nonatomic, strong) NSMutableArray *headerViews;

@end
