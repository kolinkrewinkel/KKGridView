//
//  KKGridViewCell.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKGridViewCell.h"
#import "KKGridView.h"

@implementation KKGridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize selected = _selected;
@synthesize selectedBackgroundView = _selectedBackgroundView;


#pragma mark - Class Methods

+ (NSString *)cellIdentifier
{
    return NSStringFromClass([self class]);
}

+ (id)cellForGridView:(KKGridView *)gridView
{
    NSString *cellID = [self cellIdentifier];
    KKGridViewCell *cell = (KKGridViewCell *)[gridView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[self alloc] initWithFrame:(CGRect){CGPointZero,gridView.cellSize} reuseIdentifier:cellID];
        cell.layer.borderColor = [UIColor redColor].CGColor;
        cell.layer.borderWidth = 2.f;
    }
    
    return cell;
}

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithFrame:frame])) {
        self.reuseIdentifier = reuseIdentifier;
        
        _selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _selectedBackgroundView.backgroundColor = [UIColor blueColor];
        _selectedBackgroundView.hidden = YES;
        _selectedBackgroundView.alpha = 0.f;
        [self addSubview:_selectedBackgroundView];
    }
    
    return self;
}

#pragma mark - Setters

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    if (selected == YES) {
        _selectedBackgroundView.hidden = !selected;
    }
    
    if ([UIView areAnimationsEnabled]) {
        _selectedBackgroundView.alpha = selected ? 1.f : 0.f;
    } else {
        _selectedBackgroundView.hidden = !selected;
    }
    
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent) animations:^(void) {
        self.selected = selected;
    } completion:^(BOOL finished) {
        _selectedBackgroundView.hidden = !selected;
    }];
}

#pragma mark - Drawing

- (void)layoutSubviews
{
    _selectedBackgroundView.frame = self.bounds;
    [super layoutSubviews];
}

#pragma mark - Subclassers

- (void)prepareForReuse
{
    
}

@end
