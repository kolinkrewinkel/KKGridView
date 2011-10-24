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
//  These aren't always respected depending on the accessory
    KKGridViewCellAccessoryPositionTopRight,    // 1
    KKGridViewCellAccessoryPositionTopLeft,     // 2
    KKGridViewCellAccessoryPositionBottomLeft,  // 3
    KKGridViewCellAccessoryPositionBottomRight, // 4
} KKGridViewCellAccessoryPosition;

typedef enum {
    KKGridViewCellAccessoryTypeNone, // Blank
    KKGridViewCellAccessoryTypeUnread, // Blue bullet
    KKGridViewCellAccessoryTypeReadPartial,
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

#pragma mark - Designated Initializer

+ (id)cellForGridView:(KKGridView *)gridView;
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

#pragma mark - Properties

@property (nonatomic, strong) UIView *backgroundView; // Underneath contentView, use this to customize backgrounds
@property (nonatomic, strong) UIView *contentView; // Where all subviews should be.
@property (nonatomic, copy) KKIndexPath *indexPath;
@property (nonatomic, copy) NSString *reuseIdentifier; // For usage by KKGridView
@property (nonatomic) BOOL selected; // I/O
@property (nonatomic, strong) UIView *selectedBackgroundView; // Replaces *backgroundView when selected is YES
@property (nonatomic) BOOL editing; // Editing state
@property (nonatomic) KKGridViewCellAccessoryType accessoryType; // Default is none.
@property (nonatomic) KKGridViewCellAccessoryPosition accessoryPosition; // Default is quadrant 1.

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark - Subclassers

- (void)prepareForReuse;

@end
