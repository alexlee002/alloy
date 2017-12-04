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
#import "ALModelORMBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALModelInsert : ALModelORMBase

+ (instancetype)insertModel:(Class)modelClass
                 properties:(const ALDBPropertyList &)propertiesToSave
                 onConflict:(ALDBConflictPolicy)onConflict;

- (instancetype)initWithDatabase:(ALDBHandle *)handle
                           table:(NSString *)table
                      modelClass:(Class)modelClass
                      properties:(const ALDBPropertyList &)propertiesToSave
                      onConflict:(ALDBConflictPolicy)onConflict;

- (NSInteger)changes;

- (BOOL)executeWithObjects:(NSArray *)models;

@end

NS_ASSUME_NONNULL_END
