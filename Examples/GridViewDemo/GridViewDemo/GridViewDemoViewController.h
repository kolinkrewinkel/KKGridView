//
//  GridViewDemoViewController.h
//  GridViewDemo
//
//  Created by Kolin Krewinkel on 7.25.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GridViewDemoViewController : UIViewController <KKGridViewDataSource, KKGridViewDelegate> {
    KKGridView *_gridView;
}

@end
