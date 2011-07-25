//
//  DetailViewController.h
//  GridViewExample
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@end
