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

#pragma mark - Metric Overrides

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    return CGRectMake(10.f, 0.f, bounds.size.width - 10.f, bounds.size.height);
}

@end
