//
//  KKGridViewCell.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

@class KKGridView;
@class KKIndexPath;

@interface KKGridViewCell : UIView

#pragma mark - Class Methods

+ (NSString *)cellIdentifier;
+ (id)cellForGridView:(KKGridView *)gridView;

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

#pragma mark - Properties

@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, copy) KKIndexPath *indexPath;
@property (nonatomic) BOOL selected;
@property (nonatomic, strong) UIView *selectedBackgroundView;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

#pragma mark - Subclassers

- (void)prepareForReuse;

@end
