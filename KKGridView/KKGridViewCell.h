//
//  KKGridViewCell.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 contributors. All rights reserved.
//

@interface KKGridViewCell : UIView {
    @private
    NSString *_reuseIdentifier;
}

#pragma mark - Properties

@property (nonatomic, copy) NSString *reuseIdentifier;

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

@end
