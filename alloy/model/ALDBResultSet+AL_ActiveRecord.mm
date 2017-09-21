//
//  ALDBResultSet+AL_ActiveRecord.m
//  alloy
//
//  Created by Alex Lee on 19/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultSet+AL_ActiveRecord.h"

@implementation ALDBResultSet (AL_ActiveRecord)

- (nullable NSEnumerator *)objectEnumeratorForClass:(Class /* <ALActiveRecord> */)modelClass {
    return nil;
}

@end
