//
//  ALDBResultSet.m
//  alloy
//
//  Created by Alex Lee on 17/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultSet.h"
#import <unordered_map>
#import <sqlite3.h>

typedef std::unordered_map<std::string, int> StringIndexMap;
@implementation ALDBResultSet {
    aldb::RecyclableStatement _stmt;
    
    std::shared_ptr<StringIndexMap> _nameIndexMap;
}

- (instancetype)initWithStatement:(const aldb::RecyclableStatement &)stmt {
    self = [super init];
    if (self) {
        _stmt = stmt;
        _nameIndexMap = nullptr;
    }
    return self;
}

- (NSInteger)columnCount {
    return _stmt->column_count();
}

- (NSString *)columnNameAt:(NSInteger)index {
    const char *name = _stmt->column_name((int)index);
    return name ? @(name) : nil;
}

- (NSInteger)columnIndexForName:(NSString *)name {
    if (!_nameIndexMap) {
        auto map = std::shared_ptr<StringIndexMap>(new StringIndexMap());
        for (int i = 0; i < _stmt->column_count(); ++i) {
            map->insert({_stmt->column_name(i), i});
        }
        _nameIndexMap = map;
    }

    auto iter = _nameIndexMap->find(name.UTF8String);
    if (iter != _nameIndexMap->end()) {
        return iter->second;
    }
    return NSNotFound;
}

- (BOOL)next {
    if (_stmt->step()) {
        return YES;
    }
    _stmt = nullptr;
    return NO;
}

- (NSInteger)integerValueForColumn:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self integerValueForColumnIndex:index];
}

- (NSInteger)integerValueForColumnIndex:(NSInteger)index {
    return _stmt->get_int64_value((int)index);
}

- (double)doubleValueForColumn:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self doubleValueForColumnIndex:index];
}

- (double)doubleValueForColumnIndex:(NSInteger)index {
    return _stmt->get_double_value((int)index);
}

- (BOOL)boolValueForColumn:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self boolValueForColumnIndex:index];
}

- (BOOL)boolValueForColumnIndex:(NSInteger)index {
    return _stmt->get_int32_value((int)index) != 0;
}

- (NSString *)stringValueForColumn:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self stringValueForColumnIndex:index];
}

- (NSString *)stringValueForColumnIndex:(NSInteger)index {
    const char *value = _stmt->get_text_value((int)index);
    return value ? @(value) : nil;
}

- (NSData *)dataForColumn:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self dataForColumnIndex:index];
}

- (NSData *)dataForColumnIndex:(NSInteger)index {
    size_t size = 0;
    const void *data = _stmt->get_blob_value((int)index, size);
    if (data == NULL) {
        return nil;
    }
    return [NSData dataWithBytes:data length:size];
}

- (NSDate *)dateForColumn:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self dateForColumnIndex:index];
}

- (NSDate *)dateForColumnIndex:(NSInteger)index {
    aldb::ColumnType type = _stmt->column_type((int)index);
    if (type == aldb::ColumnType::TEXT_T) {
        //TODO: need dateformater
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:[self doubleValueForColumnIndex:index]];
}

- (id)objectAtIndexedSubscript:(NSInteger)index {
    aldb::ColumnType type = _stmt->column_type((int) index);
    switch (type) {
        case aldb::ColumnType::INT64_T:
        case aldb::ColumnType::INT32_T:
            return @([self integerValueForColumnIndex:index]);
        case aldb::ColumnType::DOUBLE_T:
            return @([self doubleValueForColumnIndex:index]);
        case aldb::ColumnType::TEXT_T:
            return [self stringValueForColumnIndex:index];
        case aldb::ColumnType::BLOB_T:
            return [self dataForColumnIndex:index];
        case aldb::ColumnType::NULL_T:
            return NSNull.null;
    }
}

- (id)objectForKeyedSubscript:(NSString *)columnName {
    NSInteger index = (NSInteger)[self columnIndexForName:columnName];
    return [self objectAtIndexedSubscript:index];
}
@end
