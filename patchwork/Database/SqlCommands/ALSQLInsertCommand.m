//
//  ALSQLInsertCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLInsertCommand.h"
#import "ALSQLSelectCommand.h"
#import "BlocksKit.h"
#import "StringHelper.h"


@implementation ALSQLInsertCommand {
    NSString                   *_table;
    NSString                   *_conflictPolicy;
    NSMutableArray<NSString *> *_columns;
    NSMutableArray<NSString *> *_values;
    ALSQLSelectCommand         *_selectCommand;
}

- (ALSQLInsertBlockString)INSERT {
    return ^ALSQLInsertCommand *_Nonnull(NSString *_Nonnull table) {
        _table = [table copy];
        return self;
    };
}

- (ALSQLInsertBlockString)POLICY {
    return ^ALSQLInsertCommand *_Nonnull(NSString *_Nonnull policy) {
        _conflictPolicy = [policy copy];
        return self;
    };
}

//
//- (ALSQLInsertBlockStrings)INSERT_OR {
//    return ^ALSQLInsertCommand *_Nonnull(NSString *first, ...) {
//        va_list args;
//        va_start(args, first);
//        //table
//        NSString *val = va_arg(args, NSString *);
//        if (val != nil) {
//            _table = [val copy];
//        }
//        //policy
//        val = va_arg(args, NSString *);
//        if (val != nil) {
//            _conflictPolicy = [val copy];
//        }
//        
//        va_end(args);
//        return self;
//    };
//}


- (ALSQLInsertBlockDict)VALUES {
    return ^ALSQLInsertCommand *_Nonnull(NSDictionary *_Nonnull values) {
        _columns = [NSMutableArray arrayWithCapacity:values.count];
        _values  = [NSMutableArray arrayWithCapacity:values.count];
        [values bk_each:^(NSString *col, id val) {
            [_columns addObject:col];
            [_values addObject:val];
        }];
        return self;
    };
}

- (ALSQLInsertBlockSubSelect)SELECT {
    return ^ALSQLInsertCommand *_Nonnull(ALSQLSelectCommand *_Nonnull command) {
        _columns = [command.columns mutableCopy];
        _selectCommand = command;
        return self;
    };
}


- (nullable NSString *)sql {
    NSMutableString *sql = [@"INSERT " mutableCopy];
    if (!isEmptyString(_conflictPolicy)) {
        [sql appendString:_conflictPolicy];
    }
    [sql appendString:@" INTO "];
    
    if (isEmptyString(_table)) {
        NSAssert(NO, @"INSERT: no table specified");
        return nil;
    }
    [sql appendString:_table];
    
    if (_columns.count == 0) {
        NSAssert(NO, @"INSERT: no insert values specified");
        return nil;
    }
    [sql appendString:@"("];
    [sql appendString:[_columns componentsJoinedByString:@", "]];
    [sql appendString:@") "];
    
    if (_values.count > 0) {
        NSAssert(_values.count == _columns.count, @"INSERT: values and columns not matched");
        [sql appendString:@"VALUES("];
        [sql appendString:[[_columns bk_map:^NSString *(id _) {
            return @"?";
        }] componentsJoinedByString:@", "]];
        [sql appendString:@")"];
        
        _sqlArgs = _values;
    } else if (_selectCommand != nil) {
        [sql appendString:_selectCommand.sql];
        _sqlArgs = _selectCommand.sqlArgs;
    } else {
        [sql appendString:@" DEFAULT VALUES"];
    }
    
    return [sql copy];
}


@end
