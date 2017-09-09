//
//  ALSQLAlterTable.h
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSQLStatement.h"
#import "ALDBColumnDefine.h"

@interface ALSQLAlterTable : ALSQLStatement

- (instancetype)alterTable:(NSString *)tableName;

- (instancetype)renameTo:(NSString *)tableName;

- (instancetype)addColumn:(const ALDBColumnDefine &)columnDef;

@end
