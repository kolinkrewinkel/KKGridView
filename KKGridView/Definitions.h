//
//  Definitions.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

// Constants


// Defines

#define KKGridViewDefaultHeaderHeight 27.f

// Macros

// Place ARC macro here.

static inline bool KKCGRectIntersectsRectVertically(CGRect rect1, CGRect rect2)
{
    return (CGRectGetMinY(rect2) < CGRectGetMaxY(rect1)) && (CGRectGetMaxY(rect2) > CGRectGetMinY(rect1));
}

static inline bool KKCGRectIntersectsRectVerticallyWithPositiveNegativeMargin(CGRect rect1, CGRect rect2, CGFloat margin)
{
    return (CGRectGetMinY(rect2) - margin < CGRectGetMaxY(rect1)) && (CGRectGetMaxY(rect2) + margin > CGRectGetMinY(rect1));
}


