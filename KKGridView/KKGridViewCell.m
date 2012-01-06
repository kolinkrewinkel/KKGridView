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

@end

@implementation KKGridViewCell {
    UIButton *_badgeView;
    NSString *_badgeText;

    UIColor *_userContentViewBackgroundColor;
}

@synthesize accessoryPosition = _accessoryPosition;
@synthesize accessoryType = _accessoryType;
@synthesize backgroundView = _backgroundView;
@synthesize contentView = _contentView;
@synthesize editing = _editing;
@synthesize indexPath = _indexPath;
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize selected = _selected;
@synthesize highlighted = _highlighted;
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
        cell = [[self alloc] initWithFrame:(CGRect){ .size = gridView.cellSize } reuseIdentifier:cellID];
    }
    
    return cell;
}

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithFrame:frame])) {
        self.reuseIdentifier = reuseIdentifier;
        
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        _contentView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_contentView];
        
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_backgroundView];
        
        _selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _selectedBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[self _defaultBlueBackgroundRendition]];
        _selectedBackgroundView.hidden = YES;
        _selectedBackgroundView.alpha = 0.f;
        [self addSubview:_selectedBackgroundView];
        [self bringSubviewToFront:_contentView];
        
        [_contentView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)awakeFromNib {
	
	if (!_contentView) {
		_contentView = [[UIView alloc] initWithFrame:self.bounds];
		_contentView.backgroundColor = [UIColor whiteColor];
	}
	[self addSubview:_contentView];
	
	if (!_backgroundView) {
		_backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		_backgroundView.backgroundColor = [UIColor whiteColor];
	}
	[self addSubview:_backgroundView];
	
	if (!_selectedBackgroundView) {
		_selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
		_selectedBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[self _defaultBlueBackgroundRendition]];
	}
	_selectedBackgroundView.hidden = YES;
	_selectedBackgroundView.alpha = 0.f;
	[self addSubview:_selectedBackgroundView];
	[self bringSubviewToFront:_contentView];
	
	[_contentView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:NULL];
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

#pragma mark - Setters

- (void)setAccessoryType:(KKGridViewCellAccessoryType)accessoryType
{
    _accessoryType = accessoryType;
    [self setNeedsLayout];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [UIView animateWithDuration:KKGridViewDefaultAnimationDuration animations:^{
        self.editing = editing;
    }];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    [self layoutSubviews];        
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    [self layoutSubviews];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.2 : 0 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent) animations:^(void) {
        _selected = selected;
        _selectedBackgroundView.alpha = selected ? 1.f : 0.f;
    } completion:^(BOOL finished) {
        [self layoutSubviews];        
    }];
}

- (void)_updateSubviewSelectionState
{
    for (UIView *view in _contentView.subviews) {
        if ([view respondsToSelector:@selector(setSelected:)]) {
            UIButton *assumedButton = (UIButton *)view;
            assumedButton.selected = _highlighted || _selected;
        }
    }
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [self _updateSubviewSelectionState];
    
    _contentView.frame = self.bounds;
    _backgroundView.frame = self.bounds;
    _selectedBackgroundView.frame = self.bounds;
    
    [self sendSubviewToBack:_selectedBackgroundView];
    [self sendSubviewToBack:_backgroundView];
    [self bringSubviewToFront:_contentView];
    
    
    if (_selected || _highlighted) {
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.opaque = NO;
    } else {
        _contentView.backgroundColor = (_userContentViewBackgroundColor) ? _userContentViewBackgroundColor : [UIColor whiteColor];
    }
    
    _selectedBackgroundView.hidden = !_selected && !_highlighted;
    _backgroundView.hidden = _selected || _highlighted;
    _selectedBackgroundView.alpha = _highlighted ? 1.f : (_selected ? 1.f : 0.f);
    
    static NSBundle* bundle = nil;
    if (nil == bundle) {
        NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"KKGridView.bundle"];
        bundle = [NSBundle bundleWithPath:path];
    }

    switch (self.accessoryType) {
        case KKGridViewCellAccessoryTypeNone:
            _badgeView = nil;
            break;
        case KKGridViewCellAccessoryTypeNew:
            break;
        case KKGridViewCellAccessoryTypeInfo:
            break;
        case KKGridViewCellAccessoryTypeDelete:
            break;
        case KKGridViewCellAccessoryTypeBadgeExclamatory: {
            if (!_badgeView) {
                _badgeView = [[UIButton alloc] init];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"failure-btn" ofType:@"png"]] forState:UIControlStateNormal];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"failure-btn-press" ofType:@"png"]] forState:UIControlStateSelected];
                [_badgeView setShowsTouchWhenHighlighted:NO];
                
                [_contentView addSubview:_badgeView];
            }
            CGPoint point = CGPointZero;
            switch (_accessoryPosition) {
                case KKGridViewCellAccessoryPositionTopRight:
                    point = CGPointMake(self.bounds.size.width - 29.f, 0.f);
                    break;
                case KKGridViewCellAccessoryPositionTopLeft:
                    point = CGPointZero;
                    break;
                case KKGridViewCellAccessoryPositionBottomLeft:
                    point = CGPointMake(0.f, (self.bounds.size.height - 29.f));
                    break;
                case KKGridViewCellAccessoryPositionBottomRight:
                    point = CGPointMake(self.bounds.size.width - 29.f, (self.bounds.size.height - 29.f));
                    break;
                default:
                    break;
            }
            
            _badgeView.frame = (CGRect){point, CGSizeMake(29.f, 29.f)};
            [_contentView bringSubviewToFront:_badgeView];
            break;
        } case KKGridViewCellAccessoryTypeUnread: {
            if (!_badgeView) {
                _badgeView = [[UIButton alloc] init];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"UIUnreadIndicator" ofType:@"png"]] forState:UIControlStateNormal];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"UIUnreadIndicatorPressed" ofType:@"png"]] forState:UIControlStateSelected];
                [_contentView addSubview:_badgeView];
            }
            CGPoint point = CGPointZero;
            switch (_accessoryPosition) {
                case KKGridViewCellAccessoryPositionTopRight:
                    point = CGPointMake(self.bounds.size.width - 16.f, 3.f);
                    break;
                case KKGridViewCellAccessoryPositionTopLeft:
                    point = CGPointMake(3.f, 3.f);
                    break;
                case KKGridViewCellAccessoryPositionBottomLeft:
                    point = CGPointMake(0.f, (self.bounds.size.height - 16.f));
                    break;
                case KKGridViewCellAccessoryPositionBottomRight:
                    point = CGPointMake(self.bounds.size.width - 16.f, (self.bounds.size.height - 16.f));
                    break;
                default:
                    break;
            }
            
            _badgeView.frame = (CGRect){point, CGSizeMake(13.f, 13.f)};
            [_contentView bringSubviewToFront:_badgeView];
            
            break;
        } case KKGridViewCellAccessoryTypeReadPartial: {
            if (!_badgeView) {
                _badgeView = [[UIButton alloc] init];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"UIUnreadIndicatorPartial" ofType:@"png"]] forState:UIControlStateNormal];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"UIUnreadIndicatorPartialPressed" ofType:@"png"]] forState:UIControlStateSelected];
                [_contentView addSubview:_badgeView];
            }
            CGPoint point = CGPointZero;
            switch (_accessoryPosition) {
                case KKGridViewCellAccessoryPositionTopRight:
                    point = CGPointMake(self.bounds.size.width - 16.f, 3.f);
                    break;
                case KKGridViewCellAccessoryPositionTopLeft:
                    point = CGPointMake(3.f, 3.f);
                    break;
                case KKGridViewCellAccessoryPositionBottomLeft:
                    point = CGPointMake(0.f, (self.bounds.size.height - 16.f));
                    break;
                case KKGridViewCellAccessoryPositionBottomRight:
                    point = CGPointMake(self.bounds.size.width - 16.f, (self.bounds.size.height - 16.f));
                    break;
                default:
                    break;
            }
            
            _badgeView.frame = (CGRect){point, CGSizeMake(13.f, 13.f)};
            [_contentView bringSubviewToFront:_badgeView];
            break;
        } case KKGridViewCellAccessoryTypeBadgeNumeric: {
            if (!_badgeView) {
                _badgeView = [[UIButton alloc] init];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"failure-btn" ofType:@"png"]] forState:UIControlStateNormal];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"failure-btn-press" ofType:@"png"]] forState:UIControlStateSelected];
                [_badgeView setShowsTouchWhenHighlighted:NO];
                [_contentView addSubview:_badgeView];
            }
            CGPoint point = CGPointZero;
            switch (_accessoryPosition) {
                case KKGridViewCellAccessoryPositionTopRight:
                    point = CGPointMake(self.bounds.size.width - 29.f, 0.f);
                    break;
                case KKGridViewCellAccessoryPositionTopLeft:
                    point = CGPointZero;
                    break;
                case KKGridViewCellAccessoryPositionBottomLeft:
                    point = CGPointMake(0.f, (self.bounds.size.height - 29.f));
                    break;
                case KKGridViewCellAccessoryPositionBottomRight:
                    point = CGPointMake(self.bounds.size.width - 29.f, (self.bounds.size.height - 29.f));
                    break;
                default:
                    break;
            }
            
            _badgeView.frame = (CGRect){point, CGSizeMake(29.f, 29.f)};
            [_contentView bringSubviewToFront:_badgeView];
            break;
        } case KKGridViewCellAccessoryTypeCheckmark:
            if (!_badgeView) {
                _badgeView = [[UIButton alloc] init];
                [_badgeView setBackgroundImage:[UIImage imageWithContentsOfFile:[bundle pathForResource:@"UIPreferencesWhiteCheck" ofType:@"png"]] forState:UIControlStateNormal];
                _badgeView.userInteractionEnabled = NO;
                [_contentView addSubview:_badgeView];
            }

            CGPoint point = CGPointZero;
            switch (_accessoryPosition) {
                case KKGridViewCellAccessoryPositionTopRight:
                    point = CGPointMake(self.bounds.size.width - 14.f, 0.f);
                    break;
                case KKGridViewCellAccessoryPositionTopLeft:
                    point = CGPointZero;
                    break;
                case KKGridViewCellAccessoryPositionBottomLeft:
                    point = CGPointMake(0.f, (self.bounds.size.height - 14.f));
                    break;
                case KKGridViewCellAccessoryPositionBottomRight:
                    point = CGPointMake(self.bounds.size.width - 14.f, (self.bounds.size.height - 14.f));
                    break;
                case KKGridViewCellAccessoryPositionCenter:
                    point = CGPointMake((self.bounds.size.width - 14.f) * .5f, (self.bounds.size.height - 14.f) * .5f);
                    break;
                default:
                    break;
            }
            
            _badgeView.frame = (CGRect){point, CGSizeMake(14.f, 14.f)};
            [_contentView bringSubviewToFront:_badgeView];
            break;
        default:
            break;
    }
}

- (UIImage *)_defaultBlueBackgroundRendition
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, [UIScreen mainScreen].scale);
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    static const CGFloat colors [] = { 
        0.063f, 0.459f, 0.949f, 1.0f, 
        0.028f, 0.26f, 0.877f, 1.0f
    };
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds));
    
    CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradient, startPoint, endPoint, 0);
    
    CGGradientRelease(gradient), gradient = NULL;
    UIImage *rendition = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rendition;
}

#pragma mark - Subclassers

- (void)prepareForReuse
{
    
}

@end
