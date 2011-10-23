//
//  KKGridViewCell.m
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKGridViewCell.h>
#import <KKGridView/KKGridView.h>

@implementation KKGridViewCell {
    UIButton *_badgeView;
    NSString *_badgeText;
}

@synthesize accessoryType = _accessoryType;
@synthesize backgroundView = _backgroundView;
@synthesize contentView = _contentView;
@synthesize editing = _editing;
@synthesize indexPath = _indexPath;
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
        _selectedBackgroundView.backgroundColor = [UIColor blueColor];
        _selectedBackgroundView.hidden = YES;
        _selectedBackgroundView.alpha = 0.f;
        [self addSubview:_selectedBackgroundView];
        [self bringSubviewToFront:_contentView];
        
        self.accessoryType = KKGridViewCellAccessoryTypeBadgeExclamatory;
    }
    
    return self;
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
    
    if (selected == YES) {
        _selectedBackgroundView.hidden = !selected;
    }
    
    if ([UIView areAnimationsEnabled]) {
        _selectedBackgroundView.alpha = selected ? 1.f : 0.f;
    } else {
        _selectedBackgroundView.hidden = !selected;
    }
    
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

#pragma mark - Layout

- (void)layoutSubviews
{
    _contentView.frame = self.bounds;
    _backgroundView.frame = self.bounds;
    _selectedBackgroundView.frame = self.bounds;
    
    [self sendSubviewToBack:_selectedBackgroundView];
    [self sendSubviewToBack:_backgroundView];
    [self bringSubviewToFront:_contentView];


    if (_selected) {
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.opaque = NO;
    } else {
        _contentView.backgroundColor = [UIColor lightGrayColor];
    }
    
    _selectedBackgroundView.hidden = !_selected;
    _backgroundView.hidden = _selected;
    
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
        case KKGridViewCellAccessoryTypeBadgeExclamatory:
            if (!_badgeView) {
                _badgeView = [[UIButton alloc] init];
                [_badgeView setTitle:@"!" forState:UIControlStateNormal];
                NSArray *bundle = [NSBundle allBundles];
                NSLog(@"%@", bundle);
                [_badgeView setBackgroundImage:[UIImage imageNamed:@"AppleBadgeExclamatory.png"] forState:UIControlStateNormal];
                [_contentView addSubview:_badgeView];
            }
            
            _badgeView.frame = CGRectMake(self.bounds.size.width - (29.f + 5.f), -5.f, 29.f, 31.f);
            break;
        case KKGridViewCellAccessoryTypeUnread:
            break;
        case KKGridViewCellAccessoryTypeBadgeNumeric:
            break;
        default:
            break;
    }
}

#pragma mark - Subclassers

- (void)prepareForReuse
{
    
}

@end
