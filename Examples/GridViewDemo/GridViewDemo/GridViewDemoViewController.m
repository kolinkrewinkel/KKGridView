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

@implementation GridViewDemoViewController {
    ALAssetsLibrary *_assetsLibrary;
    NSMutableArray *_photoGroups;
    NSMutableArray *_assets;
    NSDictionary *_thumbnailCache;
    dispatch_queue _imageQueue;
}

@synthesize firstSectionCount = _firstSectionCount;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!_photoGroups)
            _photoGroups = [[NSMutableArray alloc] init];
        
        if (group)
            [_photoGroups addObject:group];
        else {
            for (ALAssetsGroup *group in _photoGroups) {
                if (!_assets)
                    _assets = [[NSMutableArray alloc] init];
                
                NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result)
                        [tempArray addObject:result];
                }];
                [_assets addObject:tempArray];
            }
            [self.gridView reloadData];
        }
        
    } failureBlock:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"LOLWAT" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }];
    
    self.title = @"Photos | GridViewDemo";
    
}

#pragma mark - KKGridViewDataSource

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView
{
    return _photoGroups.count;
}

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    return [[_photoGroups objectAtIndex:section] numberOfAssets];
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{
    KKGridViewCell *cell = [KKGridViewCell cellForGridView:gridView];
    cell.imageView.image = [UIImage imageWithCGImage:[[[_assets objectAtIndex:indexPath.section] objectAtIndex:indexPath.index] thumbnail]];
    
    return cell; 
}

- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section
{
    return 25.f;
}

- (NSString *)gridView:(KKGridView *)gridView titleForHeaderInSection:(NSUInteger)section
{
    return [[_photoGroups objectAtIndex:section] valueForProperty:ALAssetsGroupPropertyName];
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
