//
//  ALSQLStatement.h
//  alloy
//
//  Created by Alex Lee on 19/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#import "ALSQLValue.h"
#import "ALSQLClause.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface ALSQLStatement : NSObject

+ (instancetype)statement;

#ifdef __cplusplus
- (const ALSQLClause)SQLClause;
#endif

@end

NS_ASSUME_NONNULL_END
