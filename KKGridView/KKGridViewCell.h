//
//  KKGridViewCell.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKIndexPath.h"

@interface KKGridViewCell : UIView

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

#pragma mark - Properties

@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic) BOOL selected;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

#pragma mark - Subclassers

- (void)prepareForReuse;

@end
