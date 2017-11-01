//
//  ALDBIndexBinding.m
//  alloy
//
//  Created by Alex Lee on 17/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBIndexBinding.h"
#import "NSString+ALHelper.h"
#import "ALDBExpr.h"
#import "ALMD5.h"

@implementation ALDBIndexBinding {
    std::list<const ALDBIndex> _columns;
    ALDBCondition _where;
}

+ (instancetype)indexBindingWithTableName:(NSString *)tableName isUnique:(BOOL)unique {
    ALDBIndexBinding *binding = [[self alloc]init];
    binding->_table = [tableName copy];
    binding->_unique = unique;
    return binding;
}

- (void)addIndexColumn:(const ALDBIndex &)column {
    _columns.push_back(column);
}

- (void)setCondition:(const ALDBCondition &)condition {
    _where = condition;
}

- (const std::list<const ALDBIndex> &)indexColumns {
    return _columns;
}

- (const ALDBCondition &)condition {
    return _where;
}

- (aldb::SQLCreateIndex)indexCreationStatement {
    return aldb::SQLCreateIndex().create(self.indexName.UTF8String).on(_table.UTF8String, _columns).where(_where);
}

- (nullable NSString *)indexName {
    if (al_isEmptyString(_indexName)) {
        if (_columns.empty()) {
            return nil;
        }

        NSMutableString *s = [@"aldb_autoindex_" mutableCopy];
        if (_unique) {
            [s appendString:@"u_"];
        }
        [s appendString:_table];
        [s appendString:@"_"];

        NSMutableString *str = [NSMutableString string];
        for (auto o : _columns) {
            if (str.length > 0) {
                [str appendString:@"|"];
            }
            [str appendString:@(o.sql().c_str())];
        }
        [s appendString:str.al_MD5Hash];

        _indexName = [s copy];
    }
    return _indexName;
}
@end
