//
//  ALModelInsert.h
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBTypeDefines.h"
#import "ALDBStatement.h"
#import "ALDBProperty.h"

@interface ALModelInsert : NSObject

+ (instancetype)insertModel:(Class)modelClass
                 properties:(const ALDBPropertyList &)propertiesToSave
                 onConflict:(ALDBConflictPolicy)onConflict;

- (NSInteger)changes;

- (nullable ALDBStatement *)preparedStatement;

- (BOOL)executeWithObjects:(NSArray *)models;

@end
