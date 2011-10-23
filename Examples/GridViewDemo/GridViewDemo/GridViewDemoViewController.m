//
//  GridViewDemoViewController.m
//  GridViewDemo
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "GridViewDemoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <KKGridView/KKGridView.h>
#import <KKGridView/KKGridViewCell.h>
#import <KKGridView/KKIndexPath.h>

static const NSUInteger kNumSection = 40;

@interface GridViewDemoViewController ()

- (void)_setupGridView;

@end

@implementation GridViewDemoViewController
@synthesize firstSectionCount = _firstSectionCount;
@synthesize footerViews = _footerViews;
@synthesize headerViews = _headerViews;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    _headerViews = [[NSMutableArray alloc] initWithCapacity:kNumSection];
    _footerViews = [[NSMutableArray alloc] initWithCapacity:kNumSection];
    
    for (NSUInteger section = 0; section < kNumSection; section++) {
        UILabel *header = [[UILabel alloc] initWithFrame:CGRectZero];
        header.backgroundColor = [UIColor grayColor];
        header.textAlignment = UITextAlignmentCenter;
        header.text = [NSString stringWithFormat:@"Header %d", section + 1];
        [_headerViews addObject:header];
        
        UILabel *footer = [[UILabel alloc] initWithFrame:CGRectZero];
        footer.textAlignment = UITextAlignmentCenter;
        footer.text = [NSString stringWithFormat:@"Footer %d", section + 1];
        footer.backgroundColor = [UIColor colorWithRed:0.772f green:0.788f blue:0.816f alpha:1.f];
        [_footerViews addObject:footer];
    }
    
    _firstSectionCount = 7;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    searchBar.barStyle = UIBarStyleBlackTranslucent;
    searchBar.delegate = self;
    searchBar.showsCancelButton = YES;
    searchBar.userInteractionEnabled = NO;
    self.gridView.gridHeaderView = searchBar;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 20.f, 50.f)];
    footerView.backgroundColor = [UIColor darkGrayColor];
    self.gridView.gridFooterView = footerView;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationController.navigationBarHidden = YES;
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItems:)];
    UIBarButtonItem *remove = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeItems:)];
    UIBarButtonItem *multiple = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleSelectionStyle:)];
    UIBarButtonItem *forceLayout = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.gridView action:@selector(_layoutGridView)];
    
    self.toolbarItems = [NSArray arrayWithObjects:add, spacer, remove, spacer, forceLayout, spacer, multiple, nil];
    
    [self _setupGridView];
}

- (void)_setupGridView
{
    __block typeof(self) selfRef = self;

    [self.gridView setNumberOfItemsInSectionBlock:^(KKGridView *gridView, NSUInteger section) {
        switch (section) {
            case 0:
                return selfRef.firstSectionCount;
                break;
            case 1:
                return 15;
                break;
            case 2:
                return 10;
                break;
            case 3:
                return 5;
                break;
            default:
                return (section % 2) ? 4 : 7;
                break;
        }
    }];
    
    [self.gridView setNumberOfSectionsBlock:^(KKGridView *gridView) {
        return kNumSection; 
    }];
    

    [self.gridView setHeightForFooterInSectionBlock:^(KKGridView *gridView, NSUInteger section) {
        return 25.f;
    }];
    
    [self.gridView setHeightForHeaderInSectionBlock:^(KKGridView *gridView, NSUInteger section) {
        return 25.f;
    }];
    [self.gridView setCellBlock:^(KKGridView *gridView, KKIndexPath *indexPath) {
        KKGridViewCell *cell = [KKGridViewCell cellForGridView:gridView];
        cell.contentView.backgroundColor = [UIColor lightGrayColor];
        
        return cell; 
    }];
    [self.gridView setViewForFooterInSectionBlock:^(KKGridView *gridView, NSUInteger section) {
        return [selfRef.footerViews objectAtIndex:section]; 
    }];
    [self.gridView setViewForHeaderInSectionBlock:^(KKGridView *gridView, NSUInteger section) {
        return [selfRef.headerViews objectAtIndex:section];
    }];
    
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - KKGridView Senders

- (void)addItems:(id)sender
{
    NSArray *items = [NSArray arrayWithObjects:[KKIndexPath indexPathForIndex:1 inSection:0], [KKIndexPath indexPathForIndex:2 inSection:0], nil];
    
    _firstSectionCount+= [items count];
    [self.gridView insertItemsAtIndexPaths:items withAnimation:KKGridViewAnimationExplode];
}

- (void)removeItems:(id)sender
{
    NSArray *items = [NSArray arrayWithObjects:[KKIndexPath indexPathForIndex:1 inSection:0], [KKIndexPath indexPathForIndex:3 inSection:0], [KKIndexPath indexPathForIndex:0 inSection:1], nil];
    
    if (_firstSectionCount >= [items count]) {
        _firstSectionCount-= [items count];
        [self.gridView deleteItemsAtIndexPaths:items withAnimation:KKGridViewAnimationExplode];
    } else {
        NSLog(@"Warning: can't remove any more objects here");
    }
}

- (void)toggleSelectionStyle:(id)sender
{
    self.gridView.allowsMultipleSelection = !self.gridView.allowsMultipleSelection;
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:self.gridView.allowsMultipleSelection ? @"Disable Multiple Selection" : @"Enable Multiple Selection" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditingStyle:)] animated:YES];
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CATransition *fadeTransition = [CATransition animation];
    fadeTransition.duration = duration;
    fadeTransition.type = kCATransitionFade;
    fadeTransition.removedOnCompletion = YES;
    fadeTransition.fillMode = kCAFillModeForwards;
    
    for (CALayer *aLayer in self.gridView.layer.sublayers)
        [aLayer removeAllAnimations];
    
    [self.gridView.layer addAnimation:fadeTransition forKey:@"transition"];
}

@end
