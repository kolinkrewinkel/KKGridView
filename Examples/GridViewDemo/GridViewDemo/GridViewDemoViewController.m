//
//  GridViewDemoViewController.m
//  GridViewDemo
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "GridViewDemoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "KKGridViewCell.h"
#import "KKIndexPath.h"

static const NSUInteger kNumSection = 40;

@implementation GridViewDemoViewController {
    KKGridView *_gridView;
    NSMutableArray *_headerViews;
    NSMutableArray *_footerViews;
    NSUInteger kFirstSectionCount;
}


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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Enable Multiple Selection" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditingStyle:)];
    
    kFirstSectionCount = 7;
    _gridView = [[KKGridView alloc] initWithFrame:self.view.bounds dataSource:self delegate:self];
    _gridView.cellSize = CGSizeMake(75.f, 75.f);
    _gridView.scrollsToTop = YES;
    _gridView.cellPadding = CGSizeMake(4.f, 4.f);
    _gridView.allowsMultipleSelection = NO;
    _gridView.backgroundColor = [UIColor whiteColor];
    _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.bounds.size.width, 50.f)];
    headerView.backgroundColor = [UIColor darkGrayColor];
    _gridView.gridHeaderView = headerView;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 20.f, 50.f)];
    footerView.backgroundColor = [UIColor darkGrayColor];
    _gridView.gridFooterView = footerView;
    
    self.view = _gridView;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItems:)];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)addItems:(id)sender
{
    NSArray *items = [NSArray arrayWithObjects:[KKIndexPath indexPathForIndex:1 inSection:0], [KKIndexPath indexPathForIndex:3 inSection:0], [KKIndexPath indexPathForIndex:4 inSection:0], [KKIndexPath indexPathForIndex:0 inSection:1], nil];
    
    kFirstSectionCount+= [items count];
    [_gridView insertItemsAtIndexPaths:items withAnimation:KKGridViewAnimationExplode];
}

- (void)toggleEditingStyle:(id)sender
{
    _gridView.allowsMultipleSelection = !_gridView.allowsMultipleSelection;
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:_gridView.allowsMultipleSelection ? @"Disable Multiple Selection" : @"Enable Multiple Selection" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditingStyle:)] animated:YES];
}

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    switch (section) {
        case 0:
            return kFirstSectionCount;
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

- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section
{
    return 25.f;
}

- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section
{
    return [_headerViews objectAtIndex:section];
}

- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section
{
    return 35.f;
}

- (UIView *)gridView:(KKGridView *)gridView viewForFooterInSection:(NSUInteger)section
{
    return [_footerViews objectAtIndex:section];
}

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView
{
    return kNumSection;
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [KKGridViewCell cellForGridView:gridView];
    
    cell.backgroundColor = [UIColor lightGrayColor];
    
    return cell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
