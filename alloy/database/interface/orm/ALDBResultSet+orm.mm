//
//  ALDBResultSet+orm.m
//  alloy
//
//  Created by Alex Lee on 20/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultSet+orm.h"
#import "_ALModelResultEnumerator.h"
#import "ALDBProperty.h"
#import "column.hpp"

@implementation ALDBResultSet (orm)

- (NSEnumerator *)enumatorWithClass:(Class)modelClass {
    return [_ALModelResultEnumerator enumeratorWithModel:modelClass resultSet:self resultColumns:ALDBResultColumnList(ALDBProperty(aldb::Column::ANY))];
}

- (NSEnumerator *)enumatorWithClass:(Class)modelClass resultProperties:(const ALDBResultColumnList &)resultList {
    return [_ALModelResultEnumerator enumeratorWithModel:modelClass resultSet:self resultColumns:resultList];
}

@end
