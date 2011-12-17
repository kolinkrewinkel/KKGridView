//
//  KKBlocksDelegate.h
//  KKGridView
//
//  Created by Jonathan Sterling on 12/16/11.
//  Copyright (c) 2011 kxk design. All rights reserved.
//

#import <KKGridView/KKGridView.h>

// Use KKBlocksDelegate if you prefer blocks to implementing protocols.
// You need to maintain ownership of this object, since the dataSource/delegate
// references are weak.

@interface KKBlocksDelegate : NSObject <KKGridViewDataSource, KKGridViewDelegate>
@property (copy) KKGridViewCell *(^cell)(KKGridView *gridView, KKIndexPath *indexPath);
@property (copy) NSUInteger (^numberOfSections)(KKGridView *gridView);
@property (copy) NSUInteger (^numberOfItems)(KKGridView *gridView, NSUInteger section);
@property (copy) CGFloat (^heightForHeader)(KKGridView *gridView, NSUInteger section);
@property (copy) CGFloat (^heightForFooter)(KKGridView *gridView, NSUInteger section);
@property (copy) NSString *(^titleForHeader)(KKGridView *gridView, NSUInteger section);
@property (copy) NSString *(^titleForFooter)(KKGridView *gridView, NSUInteger section);
@property (copy) UIView *(^viewForHeader)(KKGridView *gridView, NSUInteger section);
@property (copy) UIView *(^viewForFooter)(KKGridView *gridView, NSUInteger section);

@property (copy) void (^didSelectItem)(KKGridView *gridView, KKIndexPath *indexPath);
@property (copy) void (^didDeselectItem)(KKGridView *gridView, KKIndexPath *indexPath);
@property (copy) KKIndexPath *(^willSelectItem)(KKGridView *gridView, KKIndexPath *indexPath);
@property (copy) KKIndexPath *(^willDeselectItem)(KKGridView *gridView, KKIndexPath *indexPath);
@property (copy) void (^willDisplayCell)(KKGridView *gridView, KKGridViewCell *cell, KKIndexPath *indexPath);
@end
