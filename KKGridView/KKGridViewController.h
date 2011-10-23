//
//  KKGridViewController.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 10.22.11.
//  Copyright (c) 2011 Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridView.h>

@interface KKGridViewController : UIViewController <KKGridViewDataSource, KKGridViewDelegate>

@property (nonatomic, strong) KKGridView *gridView;

@end
