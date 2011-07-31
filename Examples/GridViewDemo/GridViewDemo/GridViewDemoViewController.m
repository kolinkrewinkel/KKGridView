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

- (UIColor *)randomColor
{
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.f];
}

- (void)loadView
{
    [super loadView];
    

    _headerViews = [[NSMutableArray alloc] init];
    for (NSUInteger section = 0; section < kNumSection; section++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 25.f)];
        view.backgroundColor = [self randomColor];
        view.opaque = YES;
        [_headerViews addObject:view];
    }
    
    _footerViews = [[NSMutableArray alloc] init];
    for (NSUInteger section = 0; section < kNumSection; section++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = [self randomColor];
        view.layer.borderColor = [UIColor blackColor].CGColor;
        view.layer.borderWidth = 1;
        view.opaque = YES;
        [_footerViews addObject:view];
    }

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Enable Multiple Selection" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditingStyle:)];
//    [self.navigationItem setPrompt:[NSString stringWithFormat:@"Select a cell."]];

    kFirstSectionCount = 15;
    _gridView = [[KKGridView alloc] initWithFrame:self.view.bounds dataSource:self delegate:self];
    _gridView.cellSize = CGSizeMake(75.f, 75.f);
    _gridView.scrollsToTop = YES;
    _gridView.cellPadding = CGSizeMake(4.f, 4.f);
    _gridView.allowsMultipleSelection = NO;
    _gridView.backgroundColor = [UIColor darkGrayColor];
    _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    headerView.backgroundColor = [UIColor redColor];
    _gridView.gridHeaderView = headerView;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 150)];
    footerView.backgroundColor = [UIColor blueColor];
    _gridView.gridFooterView = footerView;
    
    self.view = _gridView;
    
    [self performSelector:@selector(addItems) withObject:nil afterDelay:4.0];
}

- (void)addItems
{
//    kFirstSectionCount+= 1;
//    [_gridView insertItemsAtIndexPaths:[NSArray arrayWithObjects:[KKIndexPath indexPathForIndex:0 inSection:0], nil] withAnimation:KKGridViewAnimationExplode];
}

- (void)toggleEditingStyle:(id)sender
{
    _gridView.allowsMultipleSelection = !_gridView.allowsMultipleSelection;
    if (_gridView.allowsMultipleSelection) {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Disable Multiple Selection" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditingStyle:)] animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Enable Multiple Selection" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditingStyle:)] animated:YES];
    }
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

/*- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section
{
    return 25.f;
}

- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section
{
    return [_headerViews objectAtIndex:section];
}*/

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

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForRowAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [KKGridViewCell cellForGridView:gridView];
    
    cell.backgroundColor = [UIColor lightGrayColor];
    
    return cell;
}

- (void)gridView:(KKGridView *)gridView didSelectItemIndexPath:(KKIndexPath *)indexPath
{
//    [self.navigationItem setPrompt:[NSString stringWithFormat:@"Selected cell at index: %d in section: %d.", indexPath.index, indexPath.section]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
