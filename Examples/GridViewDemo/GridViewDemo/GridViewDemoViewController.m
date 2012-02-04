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

@implementation GridViewDemoViewController
@synthesize firstSectionCount = _firstSectionCount;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    _firstSectionCount = 7;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    searchBar.barStyle = UIBarStyleBlackTranslucent;
    searchBar.delegate = self;
    searchBar.showsCancelButton = YES;
    searchBar.userInteractionEnabled = YES;
    self.gridView.gridHeaderView = searchBar;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 20.f, 50.f)];
    footerView.backgroundColor = [UIColor darkGrayColor];
    self.gridView.gridFooterView = footerView;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbar.tintColor = [UIColor darkGrayColor];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItems:)];
    UIBarButtonItem *remove = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeItems:)];
    UIBarButtonItem *multiple = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleSelectionStyle:)];
//    UIBarButtonItem *move = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(moveItems:)];
    
    self.toolbarItems = [NSArray arrayWithObjects:add, spacer, remove, spacer, spacer, multiple, nil];
}

#pragma mark - KKGridViewDataSource

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView
{
    return kNumSection;
}

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    switch (section) {
        case 0:
            return self.firstSectionCount;
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
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [KKGridViewCell cellForGridView:gridView];
    if (indexPath.index % 2) {
        cell.accessoryType = KKGridViewCellAccessoryTypeUnread;
    } else {
        cell.accessoryType = KKGridViewCellAccessoryTypeReadPartial;
    }
    cell.accessoryPosition = KKGridViewCellAccessoryPositionTopLeft;
    cell.contentView.backgroundColor = [UIColor lightGrayColor];
    
    return cell; 
}

- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section
{
    return 25.f;
}

- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section
{
    return 25.f;
}

- (NSString *)gridView:(KKGridView *)gridView titleForHeaderInSection:(NSUInteger)section
{
    return [NSString stringWithFormat:@"Header %i",section];
}

- (NSString *)gridView:(KKGridView *)gridView titleForFooterInSection:(NSUInteger)section
{
    return [NSString stringWithFormat:@"Footer %i",section];
}

- (NSArray *)sectionIndexTitlesForGridView:(KKGridView *)gridView {
    return [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - KKGridView Senders

- (void)addItems:(id)sender
{
    NSArray *items = [NSArray arrayWithObjects:[KKIndexPath indexPathForIndex:1 inSection:0], [KKIndexPath indexPathForIndex:2 inSection:0],/* [KKIndexPath indexPathForIndex:0 inSection:1],*/ nil];
    
    _firstSectionCount+= [items count];
    [self.gridView insertItemsAtIndexPaths:items withAnimation:KKGridViewAnimationExplode];
}

- (void)removeItems:(id)sender
{
    NSArray *items = [NSArray arrayWithObjects:[KKIndexPath indexPathForIndex:0 inSection:0]/*, [KKIndexPath indexPathForIndex:3 inSection:0], [KKIndexPath indexPathForIndex:0 inSection:1]*/, nil];
    
    if (_firstSectionCount >= [items count] + 1) {
        _firstSectionCount-= [items count];
        [self.gridView deleteItemsAtIndexPaths:items withAnimation:KKGridViewAnimationExplode];
    } else {
        NSLog(@"Warning: can't remove any more objects here");
    }
}

//- (void)moveItems:(id)sender
//{
////    NSUInteger num = (arc4random() % 1) + 2;
//    KKIndexPath *indexPath = [KKIndexPath indexPathForIndex:1 inSection:0];
//    KKIndexPath *destinationPath = /*num == 1 ?*/ [KKIndexPath indexPathForIndex:2 inSection:0] /*: [KKIndexPath indexPathForIndex:2 inSection:2]*/;
//    [self.gridView moveItemAtIndexPath:indexPath toIndexPath:destinationPath];
//}

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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
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
