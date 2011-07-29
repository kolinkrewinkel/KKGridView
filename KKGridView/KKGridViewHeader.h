//
//  KKGridViewHeader.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.28.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKGridViewHeader : NSObject {
    @package
    CGFloat stickPoint;
    NSUInteger section;
    BOOL sticking;
}

@property (nonatomic, retain, readonly) UIView *view;

- (id)initWithView:(UIView *)view;

@end
