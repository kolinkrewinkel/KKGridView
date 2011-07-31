//
//  GridViewDemoAppDelegate.h
//  GridViewDemo
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GridViewDemoViewController;

@interface GridViewDemoAppDelegate : NSObject <UIApplicationDelegate>
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet GridViewDemoViewController *viewController;
@end
