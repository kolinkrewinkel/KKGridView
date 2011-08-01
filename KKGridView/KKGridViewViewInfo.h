//
//  KKGridViewViewInfo.h
//  KKGridView
//
//  Created by Jonathan Sterling on 7/31/11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

@interface KKGridViewViewInfo : NSObject {
    @package
    CGFloat stickPoint;
    NSUInteger section;
    BOOL sticking;
}


@property (nonatomic, strong, readonly) UIView *view;

- (id)initWithView:(UIView *)view;

@end

@interface KKGridViewFooter : KKGridViewViewInfo
@end

@interface KKGridViewHeader : KKGridViewViewInfo
@end
