//
//  KKAppDelegate.m
//  FeatureDemo
//
//  Created by Kolin Krewinkel on 4/28/12.
//  Copyright (c) 2012 Kolin Krewinkel. All rights reserved.
//

#import "KKAppDelegate.h"

#import "KKMasterViewController.h"

#import "KKDetailViewController.h"

@implementation KKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    KKMasterViewController *masterViewController = [[KKMasterViewController alloc] initWithNibName:@"KKMasterViewController" bundle:nil];
    UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    KKDetailViewController *detailViewController = [[KKDetailViewController alloc] initWithNibName:@"KKDetailViewController" bundle:nil];
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];

    masterViewController.detailViewController = detailViewController;

    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.delegate = detailViewController;
    self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
