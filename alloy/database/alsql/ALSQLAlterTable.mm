//
//  ALSQLAlterTable.m
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLAlterTable.h"
#import "ALSQLValue.h"

@implementation ALSQLAlterTable {
    NSString *_table;
    NSString *_rename;
    std::shared_ptr<ALDBColumnDefine> _columnDef;
}

- (instancetype)alterTable:(NSString *)tableName {
    _table = [tableName copy];
    return self;
}

- (instancetype)renameTo:(NSString *)tableName {
    _rename = [tableName copy];
    _columnDef = nullptr;
    return self;
}

- (instancetype)addColumn:(const ALDBColumnDefine &)columnDef {
    _rename = nil;
    _columnDef = std::shared_ptr<ALDBColumnDefine>(new ALDBColumnDefine(columnDef));
    return self;
}

- (const ALSQLClause)SQLClause {
    ALSQLClause clause("ALTER TABLE ");
    clause.append(_table);
    
    if (_rename != nil) {
        clause.append(" RENAME TO ").append(_rename);
    }
    
    if (_columnDef) {
        clause.append(" ADD COLUMN ").append(*_columnDef);
    }
    
    return clause;
}

@end
