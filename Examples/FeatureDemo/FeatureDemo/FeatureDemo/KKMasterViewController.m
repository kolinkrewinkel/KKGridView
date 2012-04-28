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
        self.title = @"KKGridView";
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    _objects = [[NSMutableArray alloc] initWithArray:@[@"Add Items", @"Remove Items", @"Add Section", @"Remove Section", @"Move Items", @"Multiple Selection"]];
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
    if (indexPath.row == 5) {
        cell.accessoryType = self.detailViewController.gridView.allowsMultipleSelection ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }

    cell.textLabel.text = [_objects objectAtIndex:indexPath.row];

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
    switch (indexPath.row) {
        case 5:
            self.detailViewController.gridView.allowsMultipleSelection = !self.detailViewController.gridView.allowsMultipleSelection;
            break;
            
        default:
            break;
    }
}

@end
