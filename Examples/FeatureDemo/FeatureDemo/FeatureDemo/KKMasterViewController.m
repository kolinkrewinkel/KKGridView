//
//  KKMasterViewController.m
//  FeatureDemo
//
//  Created by Kolin Krewinkel on 4/28/12.
//  Copyright (c) 2012 Kolin Krewinkel. All rights reserved.
//

#import "KKMasterViewController.h"

#import "KKDetailViewController.h"

@interface KKMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation KKMasterViewController

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.title = @"Controller";
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    return self;
}



#pragma mark - Cleanup

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _objects = [[NSMutableArray alloc] initWithArray:@[@"Add Items", @"Remove Items", @"Add Section", @"Remove Section", @"Move Items", @"Multiple Selection", @"Background View", @"Begin Updates"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [_objects objectAtIndex:indexPath.row];
    
    if (indexPath.row == 5) {
        cell.accessoryType = self.detailViewController.gridView.allowsMultipleSelection ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if (indexPath.row == 6) {
        cell.accessoryType = self.detailViewController.gridView.backgroundView ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if (indexPath.row == 7) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = self.detailViewController.gridView.batchUpdating ? @"End Updates" : @"Begin Updates";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _dispatchActionForIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Grid View

- (void)_dispatchActionForIndexPath:(NSIndexPath *)indexPath
{
    KKGridView *gridView = self.detailViewController.gridView;
    
    switch (indexPath.row) {
        case 0: {
            NSMutableSet *set = [[NSMutableSet alloc] init];
            for (NSIndexPath *indexPath in [gridView visibleIndexPaths]) {
                [set addObject:[NSNumber numberWithUnsignedInteger:indexPath.section]];
            }
            
            NSArray *sections = [set allObjects];
            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
            
            for (NSString *section in sections) {
                [indexPaths addObject:[KKIndexPath indexPathForIndex:0 inSection:[section integerValue]]];
                NSMutableArray *array = [self.detailViewController.fillerData objectAtIndex:[section integerValue]];
                [array addObject:[NSString stringWithFormat:@"%u", [array count]]];
            }
            
            
            [gridView insertItemsAtIndexPaths:indexPaths withAnimation:KKGridViewAnimationExplode];
            
            break;
        } case 5: {
            gridView.allowsMultipleSelection = !gridView.allowsMultipleSelection;
            break;
        } case 6: {
            UIView *backgroundView = nil;
            if (!gridView.backgroundView) {
                backgroundView = [[UIView alloc] init];
                backgroundView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
            }
            
            gridView.backgroundView = gridView.backgroundView ? nil : backgroundView;
            
            break;
        } case 7: {

            if (!gridView.batchUpdating)
                [gridView beginUpdates];
            else
                [gridView endUpdates];

            break;
        }
        default:
            break;
    }
}

@end
