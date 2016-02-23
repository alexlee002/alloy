//
//  ALModel+DBManage.m
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel+DBManage.h"
#import "FMDatabase.h"
#import "BlocksKit.h"
#import "StringHelper.h"
#import "ALDBColumnInfo.h"
#import "UtilitiesHeader.h"
#import "NSArray+BlocksKitExtension.h"

NSString * const kInMemoryDBPath    = @":memory:";
NSString * const kTemporaryDBPath   = @":tmp:";

@implementation ALModel (DBManage)

+ (BOOL)bindedToDatabase {
    return YES;
}

+ (nullable NSDictionary<NSString *, NSString *> *)modelCustomColumnNameMapper {
    return nil;
}

+ (NSSet<NSString *> *)columnNames {
    static NSSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set  = [NSSet setWithArray:[[self columnDefines] bk_map:^NSString *(ALDBColumnInfo *obj) {
            return obj.name;
        }]];
    });
    return set;
}

+ (nullable NSArray<ALDBColumnInfo *> *)columnDefines {
    return [[[self allModelProperties] bk_map:^ALDBColumnInfo *(NSString *key, YYClassPropertyInfo *p) {
                ALDBColumnInfo *colum = [[ALDBColumnInfo alloc] init];
                colum.name     = [self modelCustomColumnNameMapper][key] ?: key;
                colum.dataType = suggestedSqliteDataType(p) ?: @"BLOB";
                return colum;
            }].allValues
        sortedArrayUsingComparator:^NSComparisonResult(ALDBColumnInfo *_Nonnull c1, ALDBColumnInfo *_Nonnull c2) {

            NSArray *allIndexedKeys = [[@[
                wrapNil([self primaryKeys]),
                wrapNil([[self uniqueKeys] al_flatten]),
                wrapNil([[self indexKeys] al_flatten])
            ] bk_reject:^BOOL(id obj) {
                return obj == NSNull.null;
            }] al_flatten];

            NSInteger idx1 = [allIndexedKeys indexOfObject:c1.name];
            NSInteger idx2 = [allIndexedKeys indexOfObject:c2.name];
            if (idx1 != NSNotFound && idx2 != NSNotFound) {
                return [@(idx1) compare:@(idx2)];
            } else if (idx1 != NSNotFound) {
                return NSOrderedAscending;
            } else if (idx2 != NSNotFound) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
}

+ (nullable NSArray<NSString *> *)primaryKeys {
    return nil;
}

+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return nil;
}

+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys {
    return nil;
}

+ (BOOL)createTable:(FMDatabase *)db {
    NSMutableArray *sqlClause = [NSMutableArray array];
    NSString *tableName = [[self tableName] stringify];
    if (tableName.length == 0) {
        return nil;
    }
    
    // CREATE TABLE
    [sqlClause addObject:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableName]];
    
    // COLUMN DEF
    [[self columnDefines] bk_each:^(ALDBColumnInfo *column) {
        [sqlClause addObject:column.description];
    }];
    
    // PRIMARY KEY
    NSArray *indexKeys = [self primaryKeys];
    if ([indexKeys count] > 0) {
        [sqlClause
         addObject:[NSString stringWithFormat:@"PRIMARY KEY (%@)", [indexKeys componentsJoinedByString:@", "]]];
    }
    
    [sqlClause addObject:@");"];
    
    if (![db executeUpdate:[sqlClause componentsJoinedByString:@""]]) {
        ALLogError(@"sql: %@\nerror: %@", [sqlClause componentsJoinedByString:@"\n"], [db lastError]);
        return NO;
    }
    
    [self createIndexes:db];
    
    return YES;
}

+ (BOOL)createIndexes:(FMDatabase *)db {
    [self database:db createIndexes:[self uniqueKeys] unique:YES];
    [self database:db createIndexes:[self indexKeys] unique:NO];
    return YES;
}

+ (BOOL)database:(FMDatabase *)db createIndexes:(nullable NSArray<NSArray<NSString *> *> *)indexKeys unique:(BOOL)unique {
    if ([indexKeys count] > 0) {
        NSString *tableName = [[self tableName] stringify];
        [indexKeys bk_each:^(NSArray<NSString *> *cols) {
            if (![cols isKindOfClass:[NSArray class]] || cols.count == 0) {
                return;
            }

            NSString *idxName = [cols componentsJoinedByString:@"_"];
            idxName           = [(unique ? @"uniq_" : @"idx_") stringByAppendingString:idxName];
            NSString *idxVal  = [cols componentsJoinedByString:@", "];

            NSString *sql = [NSString
                stringWithFormat:@"CREATE UNIQUE INDEX IF NOT EXISTS %@ ON %@(%@)", idxName, tableName, idxVal];
            if (![db executeUpdate:sql]) {
                ALLogWarn(@"sql:%@\nerror:%@", sql, [db lastError]);
            }
        }];
    }
    return YES;
}

#pragma mark -

@end


/**
 * @see https://www.sqlite.org/datatype3.html
 */
NSString * suggestedSqliteDataType(YYClassPropertyInfo *property) {
    
    switch (property.type & YYEncodingTypeMask) {
        case YYEncodingTypeBool:
        case YYEncodingTypeInt8:
        case YYEncodingTypeUInt8:
        case YYEncodingTypeInt16:
        case YYEncodingTypeUInt16:
        case YYEncodingTypeInt32:
        case YYEncodingTypeUInt32:
        case YYEncodingTypeInt64:
        case YYEncodingTypeUInt64:
            return @"INTEGER";
            
        case YYEncodingTypeFloat:
        case YYEncodingTypeDouble:
        case YYEncodingTypeLongDouble:
            return @"REAL";
            
        default: break;
    }
    
    if ([property.cls isSubclassOfClass:[NSString class]] ||
        [property.cls isSubclassOfClass:[NSURL class]]) {
        return @"TEXT";
    }
    if ([property.cls isSubclassOfClass:[NSData class]]) {
        return @"BLOB";
    }
    if ([property.cls isSubclassOfClass:[NSDate class]]) {
        return @"DATETIME"; //REAL
    }
    if ([property.cls isSubclassOfClass:[NSNumber class]]) {
        return @"NUMERIC";
    }
    
    return @"BLOB";
    
}
