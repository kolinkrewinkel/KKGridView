//
//  Definitions.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

#import <AvailabilityInternal.h>

// Defines

#define KKGridViewDefaultAnimationDuration 0.25

// Macros

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 50000
#define kk_weak weak
#define __kk_weak __weak
#else
#define kk_weak unsafe_unretained
#define __kk_weak __unsafe_unretained
#endif

#if !defined(KKInline)
#define KKInline static __inline__ __attribute__((always_inline))
#endif

KKInline BOOL KKCGRectIntersectsRectVertically(CGRect rect1, CGRect rect2)
{
    return (CGRectGetMinY(rect2) < CGRectGetMaxY(rect1)) && (CGRectGetMaxY(rect2) > CGRectGetMinY(rect1));
}

KKInline BOOL KKCGRectIntersectsRectVerticallyWithPositiveNegativeMargin(CGRect rect1, CGRect rect2, CGFloat margin)
{
    return (CGRectGetMinY(rect2) - margin < CGRectGetMaxY(rect1)) && (CGRectGetMaxY(rect2) + margin > CGRectGetMinY(rect1));
}


