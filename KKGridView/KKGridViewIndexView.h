//
//  KKGridViewIndexView.h
//  KKGridView
//
//  Created by Simon Blommegård on 2011-12-22.
//

#import <UIKit/UIKit.h>

@interface KKGridViewIndexView : UIView
@property (nonatomic, strong) NSArray *sectionIndexTitles; // Array with NSStrings
@property (nonatomic, copy) void (^sectionTracked)(NSUInteger section);
@property (nonatomic, assign) BOOL tracking;

- (void)setTracking:(BOOL)tracking location:(CGPoint)location;
@end
