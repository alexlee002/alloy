//
//  ALSQLDeleteCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLDeleteCommand.h"
#import "NSString+Helper.h"

@implementation ALSQLDeleteCommand {
    NSString *_table;
}

- (ALSQLDeleteBlockString)DELETE_FROM {
    return ^ALSQLDeleteCommand *_Nonnull(NSString *tableName) {
        _table = [tableName copy];
        return self;
    };
}

- (ALSQLDeleteConditionBlock)WHERE {
    return ^ALSQLDeleteCommand *_Nonnull(ALSQLCondition *condition) {
        _where = [condition build];
        return self;
    };
}

- (nullable NSString *)sql {
    NSMutableString *sql = [@"DELETE FROM " mutableCopy];
    
    if (isEmptyString(_table)) {
        NSAssert(NO, @"DELETE: no 'qualified-table-name' specified.");
        return nil;
    }
    
    [sql appendString:_table];
    
    // WHERE
    if (!isEmptyString(_where.sqlCondition)) {
        [sql appendString: @" WHERE "];
        [sql appendString:_where.sqlCondition];
    }
    
    _sqlArgs = _where.conditionArgs;
    return [sql copy];
}

@end
