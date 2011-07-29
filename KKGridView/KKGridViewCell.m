//
//  KKGridViewCell.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewCell.h"

@implementation KKGridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize selected = _selected;

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithFrame:frame])) {
        self.reuseIdentifier = reuseIdentifier;
    }
    
    return self;
}

#pragma mark - Setters

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    self.backgroundColor = selected ? [UIColor blueColor] : [UIColor grayColor];

    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent) animations:^(void) {
        self.selected = selected;
    } completion:nil];
}

#pragma mark - Drawing

// For future use

#pragma mark - Subclassers

- (void)prepareForReuse
{
    
}

#pragma mark - NSObject

- (void)dealloc
{
    [_reuseIdentifier release];
    [super dealloc];
}

@end
