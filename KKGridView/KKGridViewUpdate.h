//
//  KKGridViewUpdate.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <KKGridView/KKIndexPath.h>
#import <KKGridView/KKGridView.h>

typedef enum {
    KKGridViewUpdateTypeItemInsert,
    KKGridViewUpdateTypeItemDelete,
    KKGridViewUpdateTypeItemReload,
    KKGridViewUpdateTypeItemMove,
    KKGridViewUpdateTypeSectionInsert,
    KKGridViewUpdateTypeSectionDelete,
    KKGridViewUpdateTypeSectionReload
} KKGridViewUpdateType;

static BOOL const KKGridViewUpdateIsNegative[KKGridViewUpdateTypeSectionReload + 1] = {
    [KKGridViewUpdateTypeItemDelete] = YES,
    [KKGridViewUpdateTypeSectionDelete] = YES
};

@interface KKGridViewUpdate : NSObject

@property (nonatomic) KKGridViewAnimation animation;
@property (nonatomic, copy) KKIndexPath * indexPath;
@property (nonatomic) BOOL sectionUpdate;
@property (nonatomic) KKGridViewUpdateType type;
@property (nonatomic) BOOL animating;
@property (nonatomic) CFTimeInterval timestamp;
@property (nonatomic, copy) KKIndexPath *destinationPath;

- (id)initWithIndexPath:(KKIndexPath *)indexPath isSectionUpdate:(BOOL)sectionUpdate type:(KKGridViewUpdateType)type animation:(KKGridViewAnimation)animation;
+ (id)updateWithIndexPath:(KKIndexPath *)indexPath isSectionUpdate:(BOOL)sectionUpdate type:(KKGridViewUpdateType)type animation:(KKGridViewAnimation)animation;

@end
