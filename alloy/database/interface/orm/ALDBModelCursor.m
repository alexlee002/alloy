//
//  ALDBModelCursor.m
//  alloy
//
//  Created by Alex Lee on 16/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBModelCursor.h"

const NSInteger kNoCount = -1;
const NSInteger kInitPos = -1;

@implementation ALDBModelCursor {
    BOOL _shouldCountTotal;
    NSInteger _totalCountKnownSofar;
    NSInteger _totalCount;
    NSInteger _position;
    NSInteger _windowCapacity;
//    NSInteger _windowSize;
    
    NSMutableArray *_cursorWindow;
}

@end
