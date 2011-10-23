//
//  KKGridViewCell.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

// For quick reference:
// UITableViewCell

@class KKGridView;
@class KKIndexPath;

typedef enum {
    KKGridViewCellAccessoryTypeNone, // Blank
    KKGridViewCellAccessoryTypeUnread, // Blue bullet
    KKGridViewCellAccessoryTypeNew, // New badge (ala Newsstand/Sonora)
    KKGridViewCellAccessoryTypeDelete, // customish deletion
    KKGridViewCellAccessoryTypeInfo, // Info button
    KKGridViewCellAccessoryTypeBadgeExclamatory, // Messages app style error
    KKGridViewCellAccessoryTypeBadgeNumeric // SpringBoard numeric badge
} KKGridViewCellAccessoryType;

typedef enum {
    KKGridViewCellAppearanceStyleAppleDefault, // Ripped from UIKit
    KKGridViewCellAppearanceStyleChristianDalonzo // @chrisdalonzo
} KKGridViewCellAppearanceStyle;

@interface KKGridViewCell : UIView

#pragma mark - Class Methods

+ (NSString *)cellIdentifier;
+ (id)cellForGridView:(KKGridView *)gridView;

#pragma mark - Designated Initializer

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

#pragma mark - Properties

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, copy) KKIndexPath *indexPath;
@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic) BOOL selected;
@property (nonatomic, strong) UIView *selectedBackgroundView;
@property (nonatomic) BOOL editing;
@property (nonatomic) KKGridViewCellAccessoryType accessoryType;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark - Subclassers

- (void)prepareForReuse;

@end
