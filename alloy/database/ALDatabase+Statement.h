//
//  ALDatabase+Statement.h
//  alloy
//
//  Created by Alex Lee on 23/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "ALSQLStatement.h"
#import "ALSQLSelect.h"
#import "ALDBResultSet.h"

NS_ASSUME_NONNULL_BEGIN
@interface ALDatabase (Statement)

- (nullable ALDBResultSet *)query:(ALSQLSelect *)select;
- (BOOL)execute:(ALSQLStatement *)sql;

@end



NS_ASSUME_NONNULL_END
