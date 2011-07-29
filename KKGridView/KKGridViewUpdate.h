//
//  KKGridViewUpdate.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.29.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import "KKIndexPath.h"

typedef enum {
    KKGridViewUpdateTypeItemInsert,
    KKGridViewUpdateTypeItemDelete,
    KKGridViewUpdateTypeItemReload,
    KKGridViewUpdateTypeSectionInsert,
    KKGridViewUpdateTypeSectionDelete,
    KKGridViewUpdateTypeSectionReload
} KKGridViewUpdateType;

@interface KKGridViewUpdate : NSObject

@property (nonatomic, copy) KKIndexPath * indexPath;
@property (nonatomic) BOOL sectionUpdate;
@property (nonatomic) KKGridViewUpdateType type;

@end
