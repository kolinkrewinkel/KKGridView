//
//  KKGridViewCell.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewCell.h>
#import <KKGridView/KKGridView.h>

@interface KKGridViewCell ()
- (UIImage *)_defaultBlueBackgroundRendition;
- (void)_updateSubviewSelectionState;
- (void)_layoutAccessories;
@end

@implementation KKGridViewCell {
    UIButton *_badgeView;
    UIColor *_userContentViewBackgroundColor;
    BOOL _ignoreUserContentViewBackground;
}

@synthesize accessoryPosition = _accessoryPosition;
@synthesize accessoryType = _accessoryType;
@synthesize backgroundView = _backgroundView;
@synthesize contentView = _contentView;
@synthesize imageView = _imageView;
@synthesize editing = _editing;
@synthesize indexPath = _indexPath;
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize selected = _selected;
@synthesize highlighted = _highlighted;
@synthesize selectedBackgroundView = _selectedBackgroundView;
@synthesize highlightAlpha = _highlightAlpha;


#pragma mark - Class Methods

+ (NSString *)cellIdentifier
{
    return NSStringFromClass(self);
}

+ (id)cellForGridView:(KKGridView *)gridView
{
    NSString *cellID = [self cellIdentifier];
    KKGridViewCell *cell = (KKGridViewCell *)[gridView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[self alloc] initWithFrame:(CGRect){ .size = gridView.cellSize } reuseIdentifier:cellID];
    }
    
    return cell;
}

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithFrame:frame])) {
        _reuseIdentifier = reuseIdentifier;
        
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_backgroundView];

        _highlightAlpha = 1.0f;

        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        _contentView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_contentView];
        [self addSubview:_selectedBackgroundView];
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_imageView];
        
        [_contentView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)awakeFromNib {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        _contentView.backgroundColor = [UIColor whiteColor];
    }
    
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIColor whiteColor];
    }
    
    [self addSubview:_backgroundView];
    [self addSubview:_contentView];
    
    [self bringSubviewToFront:_contentView];
    [self bringSubviewToFront:_badgeView];
    
    [_contentView addObserver:self 
                   forKeyPath:@"backgroundColor" 
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
}

- (void)dealloc
{
    [_contentView removeObserver:self forKeyPath:@"backgroundColor"];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _contentView && !_selected && !_highlighted) {
        _userContentViewBackgroundColor = [change objectForKey:@"new"];
    }
}

#pragma mark - Getters

- (UIView *)selectedBackgroundView
{
	if (!_selectedBackgroundView)
		_selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];

    _selectedBackgroundView.hidden = YES;
    _selectedBackgroundView.alpha = 0.f;

	return _selectedBackgroundView;
}

#pragma mark - Setters

- (void)setAccessoryType:(KKGridViewCellAccessoryType)accessoryType
{
    if (_accessoryType != accessoryType) {
        _accessoryType = accessoryType;
        [self setNeedsLayout];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        UIView.animationDuration = KKGridViewDefaultAnimationDuration;
    }
    
    self.editing = editing;
    
    if (animated)
        [UIView commitAnimations];
}

- (void)setPressedState:(BOOL)pressedState
{
    if (pressedState) {
        if (!_selectedBackgroundView)
            _selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];

        if (!_selectedBackgroundView.superview)
            [self addSubview:_selectedBackgroundView];

        if (!_selectedBackgroundView.backgroundColor)
            _selectedBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[self _defaultBlueBackgroundRendition]];

        _selectedBackgroundView.hidden = NO;
        _selectedBackgroundView.alpha = 1.f;
    } else {
        _selectedBackgroundView.hidden = YES;
        _selectedBackgroundView.alpha = 0.f;
    }
    
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [self setPressedState:selected];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        [self setPressedState:highlighted];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selected != selected) {
        NSTimeInterval duration = animated ? 0.2 : 0;
        UIViewAnimationOptions opts = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent;
        
        [UIView animateWithDuration:duration delay:0 options:opts animations:^{
            self.selected = selected; // use property access to go through the setter
            _selectedBackgroundView.alpha = selected ? _highlightAlpha : 0.f;
        } completion:^(BOOL finished) {
            [self setNeedsLayout];
        }];
    }
}

- (void)setSelectedBackgroundView:(UIView *)selectedBackgroundView
{
    if (_selectedBackgroundView == selectedBackgroundView)
        return;
    
    _ignoreUserContentViewBackground = !!_selectedBackgroundView; // if we have a custom background view, we don't set the color.
    
    if (selectedBackgroundView)
        _selectedBackgroundView = selectedBackgroundView;
    else _selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
}

- (void)_updateSubviewSelectionState
{
    for (UIControl *control in _contentView.subviews) {
        if ([control respondsToSelector:@selector(setSelected:)]) {
            control.selected = _highlighted || _selected;
        }
    }
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [self _updateSubviewSelectionState];
    
	CGRect bounds = self.bounds;
    _contentView.frame = bounds;

	if (!_backgroundView.hidden)
		_backgroundView.frame = bounds;
	else _selectedBackgroundView.frame = bounds;
    
	if (_selectedBackgroundView)
		[self sendSubviewToBack:_selectedBackgroundView];
    
    [self sendSubviewToBack:_backgroundView];
    [self bringSubviewToFront:_contentView];
    [self bringSubviewToFront:_selectedBackgroundView];
    [self bringSubviewToFront:_badgeView];
    
    if (_selected || _highlighted) {
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.opaque = NO;

        _backgroundView.hidden = YES;
        _selectedBackgroundView.hidden = NO;
        _selectedBackgroundView.alpha = _highlightAlpha;
    } else {
        _contentView.backgroundColor = _userContentViewBackgroundColor ? _userContentViewBackgroundColor : [UIColor whiteColor];
        
        _backgroundView.hidden = NO;
        _selectedBackgroundView.hidden = YES;
        _selectedBackgroundView.alpha = 0.f;
    }
    
    [self _layoutAccessories];
}

- (void)_layoutAccessories
{
    static const NSUInteger badgeCount = KKGridViewCellAccessoryTypeCheckmark + 1;
    static UIImage *normalBadges[badgeCount] = {0};
    static UIImage *pressedBadges[badgeCount] = {0};
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"KKGridView.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        UIImage *(^getBundleImage)(NSString *) = ^(NSString *n) {
            return [UIImage imageWithContentsOfFile:[bundle pathForResource:n ofType:@"png"]];
        };
        
        normalBadges[KKGridViewCellAccessoryTypeBadgeExclamatory] = getBundleImage(@"failure-btn");
        normalBadges[KKGridViewCellAccessoryTypeUnread] = getBundleImage(@"UIUnreadIndicator");
        normalBadges[KKGridViewCellAccessoryTypeReadPartial] = getBundleImage(@"UIUnreadIndicatorPartial");
        normalBadges[KKGridViewCellAccessoryTypeBadgeNumeric] = getBundleImage(@"failure-btn");
        normalBadges[KKGridViewCellAccessoryTypeCheckmark] = getBundleImage(@"UIPreferencesWhiteCheck");
        
        pressedBadges[KKGridViewCellAccessoryTypeBadgeExclamatory] = getBundleImage(@"failure-btn-pressed");
        pressedBadges[KKGridViewCellAccessoryTypeUnread] = getBundleImage(@"UIUnreadIndicatorPressed");
        pressedBadges[KKGridViewCellAccessoryTypeReadPartial] = getBundleImage(@"UIUnreadIndicatorPartialPressed");
        pressedBadges[KKGridViewCellAccessoryTypeBadgeNumeric] = getBundleImage(@"failure-btn-pressed");
    });
    
    
    switch (self.accessoryType) {
        case KKGridViewCellAccessoryTypeNone:
            [_badgeView removeFromSuperview];
        case KKGridViewCellAccessoryTypeNew:
        case KKGridViewCellAccessoryTypeInfo:
        case KKGridViewCellAccessoryTypeDelete:
            break;
        default: {
            if (!_badgeView) _badgeView = [[UIButton alloc] init];
            if (![_badgeView superview]) [self addSubview:_badgeView];
            
            [self bringSubviewToFront:_badgeView];
            break;   
        }
    }
    
    _badgeView.userInteractionEnabled = NO;
    
    static const struct { CGFloat sideLength; CGFloat offset; } map[] = {
        [KKGridViewCellAccessoryTypeBadgeExclamatory] = {29.f, 0.f},
        [KKGridViewCellAccessoryTypeUnread]           = {16.f, 3.f},
        [KKGridViewCellAccessoryTypeReadPartial]      = {16.f, 3.f},
        [KKGridViewCellAccessoryTypeBadgeNumeric]     = {29.f, 0.f},
        [KKGridViewCellAccessoryTypeCheckmark]        = {14.f, 0.f},
    };
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat s = map[self.accessoryType].sideLength;
    CGFloat o = map[self.accessoryType].offset;
    
    CGPoint const pointMap[] = {
        [KKGridViewCellAccessoryPositionTopRight]    = {w - s, o},
        [KKGridViewCellAccessoryPositionTopLeft]     = {o, o},
        [KKGridViewCellAccessoryPositionBottomLeft]  = {.y = h - s},
        [KKGridViewCellAccessoryPositionBottomRight] = {w - s, h - s},
        [KKGridViewCellAccessoryPositionCenter]      = {(w - s)/2, (h - s)/2}
    };
    
    _badgeView.frame = (CGRect){pointMap[_accessoryPosition], {s-o, s-o}}; 
    
    if (normalBadges[self.accessoryType])
    {
        [_badgeView setBackgroundImage:normalBadges[self.accessoryType] forState:UIControlStateNormal];   
    }
    
    if (pressedBadges[self.accessoryType])
    {
        [_badgeView setBackgroundImage:pressedBadges[self.accessoryType] forState:UIControlStateSelected];
    }
}

- (UIImage *)_defaultBlueBackgroundRendition
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, [UIScreen mainScreen].scale);
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    static const CGFloat colors[] = { 
        0.063f, 0.459f, 0.949f, 1.0f, 
        0.028f, 0.26f, 0.877f, 1.0f
    };
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGFloat horizontalCenter = CGRectGetMidX(self.bounds);
    CGPoint startPoint = CGPointMake(horizontalCenter, CGRectGetMinY(self.bounds));
    CGPoint endPoint = CGPointMake(horizontalCenter, CGRectGetMaxY(self.bounds));
    
    CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradient, startPoint, endPoint, 0);
    
    CGGradientRelease(gradient), gradient = NULL;
    UIImage *rendition = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rendition;
}

#pragma mark - Subclassers

- (void)prepareForReuse
{
    self.selected = NO;
}

@end
