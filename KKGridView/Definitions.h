//
//  Definitions.h
//  KKGridView
//
//  Created by Kolin Krewinkel on 7.24.11.
//  Copyright 2011 Giulio Petek, Jonathan Sterling, and Kolin Krewinkel. All rights reserved.
//

// Place ARC macro here.

inline bool KKCGRectIntersectsRectVertically(CGRect rect1, CGRect rect2)
{
    return (CGRectGetMinY(rect2) < CGRectGetMaxY(rect1)) && (CGRectGetMaxY(rect2) > CGRectGetMinY(rect1));
}

#define KKGridViewDefaultHeaderHeight 27.f