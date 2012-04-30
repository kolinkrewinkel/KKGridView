//
//  KKDetailViewController.m
//  FeatureDemo
//
//  Created by Kolin Krewinkel on 4/28/12.
//  Copyright (c) 2012 Kolin Krewinkel. All rights reserved.
//

#import "KKDetailViewController.h"
#import "KKDemoCell.h"

@interface KKDetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation KKDetailViewController

@synthesize fillerData = _fillerData;

#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Detail", @"Detail");

    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    self.gridView.backgroundView = backgroundView;
    
    _fillerData = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < 20; i++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSUInteger j = 0; j < 20; j++) {
            [array addObject:[NSString stringWithFormat:@"%u", j]];
        }

        [_fillerData addObject:array];
    }

    [self.gridView reloadData];
}

#pragma mark - KKGridView

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView
{
    return _fillerData.count;
}

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    return [[_fillerData objectAtIndex:section] count];
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{    
    KKDemoCell *cell = [KKDemoCell cellForGridView:gridView];
    cell.contentView.backgroundColor = [UIColor lightGrayColor];
    cell.label.text = [NSString stringWithFormat:@"%u", indexPath.index];

    return cell;
}

#pragma mark - Cleanup

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
