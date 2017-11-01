//
//  _ALModelResultEnumerator.h
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBResultSet.h"
#import "ALDBResultColumn.h"

@interface _ALModelResultEnumerator : NSEnumerator

+ (NSEnumerator *)enumeratorWithModel:(Class)cls
                            resultSet:(ALDBResultSet *)resultSet
                        resultColumns:(const ALDBResultColumnList &)columns;

@end
