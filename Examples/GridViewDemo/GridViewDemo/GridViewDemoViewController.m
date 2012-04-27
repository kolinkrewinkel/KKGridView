//
//  GridViewDemoViewController.m
//  GridViewDemo
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "GridViewDemoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <KKGridView/KKGridView.h>
#import <KKGridView/KKGridViewCell.h>
#import <KKGridView/KKIndexPath.h>

static const NSUInteger kNumSection = 40;

@implementation GridViewDemoViewController {
    ALAssetsLibrary *_assetsLibrary;
    NSMutableArray *_photoGroups;
    NSMutableArray *_assets;
    NSCache *_thumbnailCache;
    dispatch_queue_t _imageQueue;
}

@synthesize firstSectionCount = _firstSectionCount;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.title = @"GridViewDemo / Photos";
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    self.gridView.backgroundView = backgroundView;
    
    //    Create the assets library object; retain it to deal with iOS's retardation.
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    //    Enumerate through the user's photos.
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if (!_photoGroups)
            _photoGroups = [[NSMutableArray alloc] init];
        
        if (group)
            [_photoGroups addObject:group];
        else {
            for (ALAssetsGroup *group in _photoGroups) {
                if (!_assets)
                    _assets = [[NSMutableArray alloc] init];
                
                //                More enumeration bullshit.
                NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result)
                        [tempArray addObject:result];
                    else
                        [_assets addObject:tempArray];
                }];
            }
            [self.gridView reloadData];
            _imageQueue = dispatch_queue_create("com.kolinkrewinkel.GridViewDemo", NULL);
            
            dispatch_sync(_imageQueue, ^(void) {
                if (!_thumbnailCache)
                    _thumbnailCache = [[NSCache alloc] init]; // Thanks @indragie.
                
                NSUInteger section = 0;
                for (NSMutableArray *array in _assets) {
                    NSUInteger index = 0;
                    for (ALAsset *asset in array) {
                        [_thumbnailCache setObject:[UIImage imageWithCGImage:[asset thumbnail]] forKey:asset]; // Store it!
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.gridView reloadItemsAtIndexPaths:[NSArray arrayWithObject:[KKIndexPath indexPathForIndex:index inSection:section]]];
                        });
                        index++;
                    }
                    section++;
                }
            });
        }
        
    } failureBlock:^(NSError *error) {
        //        I can't help you here, son.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"LOLWAT" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }];
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
    
    ALAsset *asset = [[_assets objectAtIndex:indexPath.section] objectAtIndex:indexPath.index];
    cell.imageView.image = [_thumbnailCache objectForKey:asset];
    
    return cell;
}

- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section
{
    return 23.f;
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
    //    Please have your app conform to this.
    
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
