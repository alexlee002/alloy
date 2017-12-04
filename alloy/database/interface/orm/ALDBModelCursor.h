//
//  ALDBModelCursor.h
//  alloy
//
//  Created by Alex Lee on 16/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

///TODO: experimental feature, not finished yet!
@interface ALDBModelCursor : NSObject
@property(nonatomic, readonly) NSInteger totalCount;
@property(nonatomic, readonly) NSInteger totalCountKnownSofar;
@property(nonatomic, readonly) NSInteger position;

- (BOOL)moveToFirst;
- (BOOL)moveToLast;
- (BOOL)moveNext;
- (BOOL)movePervious;
- (BOOL)moveOffset:(NSInteger)offset;
- (BOOL)moveToPosition:(NSInteger)pos;
- (NSObject *)getModel;

@end
