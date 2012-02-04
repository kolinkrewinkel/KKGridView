//
//  KKBlocksDelegate.m
//  KKGridView
//
//  Created by Jonathan Sterling on 12/16/11.
//  Copyright (c) 2011 kxk design. All rights reserved.
//

#import "KKBlocksDelegate.h"

@implementation KKBlocksDelegate
@synthesize cell = _cell;
@synthesize numberOfSections = _numberOfSections;
@synthesize numberOfItems = _numberOfItems;
@synthesize heightForHeader = _heightForHeader;
@synthesize heightForFooter = _heightForFooter;
@synthesize titleForHeader = _titleForHeader;
@synthesize titleForFooter = _titleForFooter;
@synthesize viewForHeader = _viewForHeader;
@synthesize viewForFooter = _viewForFooter;

@synthesize didSelectItem = _didSelectItem;
@synthesize didDeselectItem = _didDeselectItem;
@synthesize willSelectItem = _willSelectItem;
@synthesize willDeselectItem = _willDeselectItem;
@synthesize willDisplayCell = _willDisplayCell;

#pragma mark - KKGridViewDataSource

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    return _numberOfItems ? _numberOfItems(gridView,section) : 0;
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{
    return _cell ? _cell(gridView,indexPath) : [KKGridViewCell cellForGridView:gridView];
}

- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView
{
    return _numberOfSections ? _numberOfSections(gridView) : 1;
}

- (NSString *)gridView:(KKGridView *)gridView titleForHeaderInSection:(NSUInteger)section
{
    return _titleForHeader ? _titleForFooter(gridView,section) : @"";
}

- (NSString *)gridView:(KKGridView *)gridView titleForFooterInSection:(NSUInteger)section
{
    return _titleForFooter ? _titleForFooter(gridView,section) : @"";
}

- (CGFloat)gridView:(KKGridView *)gridView heightForHeaderInSection:(NSUInteger)section
{
    return _heightForHeader ? _heightForHeader(gridView,section) : 25.0;
}

- (CGFloat)gridView:(KKGridView *)gridView heightForFooterInSection:(NSUInteger)section
{
    return _heightForFooter ? _heightForFooter(gridView,section) : 25.0;
}

- (UIView *)gridView:(KKGridView *)gridView viewForHeaderInSection:(NSUInteger)section
{
    return _viewForHeader ? _viewForHeader(gridView,section) : nil;
}

- (UIView *)gridView:(KKGridView *)gridView viewForFooterInSection:(NSUInteger)section
{
    return _viewForFooter ? _viewForFooter(gridView,section) : nil;
}

#pragma mark - KKGridViewDelegate

- (void)gridView:(KKGridView *)gridView didSelectItemAtIndexPath:(KKIndexPath *)indexPath
{
    if (_didSelectItem)
        _didSelectItem(gridView,indexPath);
}

- (void)gridView:(KKGridView *)gridView didDeselectItemAtIndexPath:(KKIndexPath *)indexPath
{
    if (_didDeselectItem)
        _didDeselectItem(gridView,indexPath);
}

- (KKIndexPath *)gridView:(KKGridView *)gridView willSelectItemAtIndexPath:(KKIndexPath *)indexPath
{
    return _willSelectItem ? _willSelectItem(gridView,indexPath) : indexPath;
}

- (KKIndexPath *)gridView:(KKGridView *)gridView willDeselectItemAtIndexPath:(KKIndexPath *)indexPath
{
    return _willDeselectItem ? _willDeselectItem(gridView,indexPath) : indexPath;
}

- (void)gridView:(KKGridView *)gridView willDisplayCell:(KKGridViewCell *)cell atIndexPath:(KKIndexPath *)indexPath
{
    if (_willDisplayCell)
        _willDisplayCell(gridView,cell,indexPath);
}

@end
