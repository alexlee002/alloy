//
//  ALDBResultSet+orm.h
//  alloy
//
//  Created by Alex Lee on 20/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultSet.h"
#ifdef __cplusplus
#import "ALDBResultColumn.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface ALDBResultSet (orm)

- (nullable NSEnumerator *)enumatorWithClass:(Class)modelClass;

#ifdef __cplusplus
- (nullable NSEnumerator *)enumatorWithClass:(Class)modelClass
                            resultProperties:(const ALDBResultColumnList &)resultList;
#endif

@end
NS_ASSUME_NONNULL_END
