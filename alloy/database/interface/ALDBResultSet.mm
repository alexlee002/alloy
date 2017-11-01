//
//  ALDBResultSet.m
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultSet.h"
#import "ALDBResultSet_Private.h"
#import "ALLogger.h"
#import "NSError+ALDBError.h"
#import "NSDate+ALExtensions.h"

@implementation ALDBResultSet

- (instancetype)initWithCoreStatementHandle:(aldb::RecyclableStatement &)coreStmtHandle
                               SQLStatement:(const std::shared_ptr<aldb::SQLStatement>)sqlstmt{
    if (!coreStmtHandle) {
        return nil;
    }
    
    self = [self init];
    if (self) {
        _coreStmtHandle = coreStmtHandle;
        _sqlStmt = sqlstmt;
    }
    return self;
}

- (BOOL)hasError {
    return _coreStmtHandle->has_error();
}

- (NSError *)lastError {
    auto err = _coreStmtHandle->get_error();
    if (err) {
        return [NSError errorWithALDBError: *err];
    }
    return nil;
}

- (NSInteger)columnsCount {
    return _coreStmtHandle->column_count();
}

- (nullable NSString *)columnNameAtIndex:(NSInteger)index {
    return @(_coreStmtHandle->column_name((int)index));
}

- (NSInteger)columnIndexForName:(NSString *)name {
    return _coreStmtHandle->column_index(name.UTF8String);
}

- (ALDBColumnType)columnTypeAtIndex:(NSInteger)index {
    return (ALDBColumnType)_coreStmtHandle->column_type((int)index);
}

- (BOOL)next {
    return _coreStmtHandle->next_row();
}

- (NSInteger)integetForColumn:(NSString *)columnName {
    return [self integerForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSInteger)integerForColumnIndex:(NSInteger)index {
    return (NSInteger)_coreStmtHandle->get_int64_value((int)index);
}

- (double)doubleForColumn:(NSString *)columnName {
    return [self doubleForColumnIndex:[self columnIndexForName:columnName]];
}

- (double)doubleForColumnIndex:(NSInteger)index {
    return _coreStmtHandle->get_double_value((int)index);
}

- (BOOL)boolForColumn:(NSString *)columnName {
    return [self boolForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)boolForColumnIndex:(NSInteger)index {
    return _coreStmtHandle->get_int32_value((int)index) != 0;
}

- (nullable NSString *)stringForColumn:(NSString *)columnName {
    return [self stringForColumnIndex:[self columnIndexForName:columnName]];
}

- (nullable NSString *)stringForColumnIndex:(NSInteger)index {
    const char *s = _coreStmtHandle->get_text_value((int)index);
    return s ? @(s) : nil;
}

- (nullable NSData *)dataForColumn:(NSString *)columnName {
    return [self dataForColumnIndex:[self columnIndexForName:columnName]];
}

- (nullable NSData *)dataForColumnIndex:(NSInteger)index {
    size_t size = 0;
    const void *data = _coreStmtHandle->get_blob_value((int)index, size);
    if (data == NULL) {
        return nil;
    }
    return [NSData dataWithBytes:data length:size];
}

- (nullable NSDate *)dateForColumn:(NSString *)columnName {
    return [self dateForColumnIndex:[self columnIndexForName:columnName]];
}

- (nullable NSDate *)dateForColumnIndex:(NSInteger)index {
    aldb::ColumnType ct = _coreStmtHandle->column_type((int) index);
    if (ct == aldb::ColumnType::INT32_T
        || ct == aldb::ColumnType::INT64_T
        || ct == aldb::ColumnType::DOUBLE_T) {
        
        NSTimeInterval t = [self doubleForColumnIndex:index];
        return [NSDate dateWithTimeIntervalSince1970:t];
        
    } else if (ct == aldb::ColumnType::TEXT_T) {
        NSString *s = [self stringForColumnIndex:index];
        return [NSDate al_dateFromFormattedString:s];
    } else {
        NSData *d = [self dataForColumnIndex:index];
        NSDate *value = nil;
        @try {
            value = [NSKeyedUnarchiver unarchiveObjectWithData:d];
            if ([value isKindOfClass:NSDate.class]) {
                return value;
            }
        } @catch (NSException *exception) {
            ALLogWarn(@"extract NSDate from column at :%d exception: %@", index, exception);
        }
        return value;
    }
}

- (nullable id)objectAtIndexedSubscript:(NSInteger)index {
    aldb::ColumnType type = _coreStmtHandle->column_type((int) index);
    switch (type) {
        case aldb::ColumnType::INT64_T:
        case aldb::ColumnType::INT32_T:
            return @([self integerForColumnIndex:index]);
        case aldb::ColumnType::DOUBLE_T:
            return @([self doubleForColumnIndex:index]);
        case aldb::ColumnType::TEXT_T:
            return [self stringForColumnIndex:index];
        case aldb::ColumnType::BLOB_T:
            return [self dataForColumnIndex:index];
        case aldb::ColumnType::NULL_T:
            return NSNull.null;
    }
}

- (nullable id)objectForKeyedSubscript:(NSString *)columnName {
    return [self objectAtIndexedSubscript:[self columnIndexForName:columnName]];
}

- (NSString *)sql {
    const char *sql = _coreStmtHandle->sql();
    return sql ? @(sql) : nil;
}
- (NSString *)expandedSQL {
    const char *sql = _coreStmtHandle->expanded_sql();
    return sql ? @(sql) : nil;
}
@end
