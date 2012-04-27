//
//  KKGridViewSectionLabel.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 4/26/12.
//  Copyright (c) 2012 Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewSectionLabel.h"

@implementation KKGridViewSectionLabel

#pragma mark - Designated Initializer

- (id)initWithString:(NSString *)string
{
    if ((self = [super initWithFrame:CGRectZero])) {
        self.textColor = [UIColor whiteColor];
        self.font = [UIFont boldSystemFontOfSize:16.f];
        self.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
        self.shadowOffset = CGSizeMake(0.f, 1.f);
        self.textAlignment = UITextAlignmentLeft;
        self.text = string;
    }

    return self;
}

#pragma mark - Drawing

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0.f, 12.f, 0.f, 0.f);
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
