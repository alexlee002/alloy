//
//  __ALResultSetEnumerator.h
//  alloy
//
//  Created by Alex Lee on 23/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBResultSet.h"
#import "ALSQLSelect.h"
#import "ALDBResultColumn.h"

@interface __ALResultSetEnumerator : NSEnumerator

+ (NSEnumerator *)enumatorWithResultSet:(ALDBResultSet *)rs
                             modelClass:(Class)cls
                          resultColumns:(const std::list<const ALDBResultColumn>)columns;

@end
