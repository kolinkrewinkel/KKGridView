//
//  KKMasterViewController.h
//  FeatureDemo
//
//  Created by Kolin Krewinkel on 4/28/12.
//  Copyright (c) 2012 Kolin Krewinkel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KKDetailViewController;

@interface KKMasterViewController : UITableViewController

@property (strong, nonatomic) KKDetailViewController *detailViewController;

- (void)_dispatchActionForIndexPath:(NSIndexPath *)indexPath;

@end
