//
//  KKGridViewHeader.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.28.11.
//  Copyright 2011 kxk design. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKGridViewHeader : NSObject
@property (nonatomic, retain, readonly) UIView *view;

@property (nonatomic, assign) CGFloat stickPoint;
@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, assign) BOOL sticking;
- (id)initWithView:(UIView *)view;

@end
