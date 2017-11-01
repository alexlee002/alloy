//
//  ALDBStatement+orm.h
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBStatement.h"

@interface ALDBStatement (orm)

- (nullable NSEnumerator *)objectEnumerator;
- (nullable NSArray *)allObjects;

@end
