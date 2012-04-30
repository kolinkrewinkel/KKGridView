//
//  KKDetailViewController.h
//  FeatureDemo
//
//  Created by Kolin Krewinkel on 4/28/12.
//  Copyright (c) 2012 Kolin Krewinkel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KKGridView/KKGridViewController.h>

@interface KKDetailViewController : KKGridViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *fillerData;
@end
