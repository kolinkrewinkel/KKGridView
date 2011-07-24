//
//  KKGridViewCell.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 contributors. All rights reserved.
//

#import "KKGridViewCell.h"

@implementation KKGridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithFrame:frame])) {
        self.reuseIdentifier = reuseIdentifier;
    }
    
    return self;
}

#pragma mark - NSObject

- (void)dealloc
{
    [_reuseIdentifier release];
    [super dealloc];
}

@end
