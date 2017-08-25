//
//  NSObject+AL_ActiveRecord.m
//  patchwork
//
//  Created by Alex Lee on 27/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+AL_ActiveRecord.h"
#import "__ALResultSetEnumerator.h"
#import "ALDatabase+Statement.h"
#import "YYClassInfo.h"
#import "ALActiveRecord.h"
#import "ALSQLSelect.h"

@implementation NSObject (AL_ActiveRecord)

+ (nullable ALDatabase *)database {
    static NSString *const selName = NSStringFromSelector(@selector(databaseIdentifier));
    NSDictionary *methods = [YYClassInfo classInfoWithClass:self].methodInfos;
    if (methods[selName] == nil) {
        return nil;
    }
    NSString *path = [(id<ALActiveRecord>)self databaseIdentifier];
    if (path == nil) {
        return nil;
    }
    return [ALDatabase databaseWithPath:path keepAlive:YES];
}

+ (nullable NSArray<id<ALActiveRecord>> *)al_modelsWithCondition:(const ALDBCondition &)condition {
    NSMutableArray *objects = [NSMutableArray array];
    for (id obj in [self al_modelEnumeratorWithCondition:condition]) {
        if (obj != nil) {
            [objects addObject: obj];
        }
    }
    return objects;
}

+ (nullable NSEnumerator<id<ALActiveRecord>> *)al_modelEnumeratorWithCondition:(const ALDBCondition &)condition {
    const std::list<const ALDBResultColumn> resultColumns = {ALDBResultColumn(ALDBColumn::s_any)};

    ALSQLSelect *stmt = [[[[ALSQLSelect statement] select:resultColumns distinct:NO]
        from:[(id<ALActiveRecord>) self tableName]] where:condition];

    ALDBResultSet *rs = [[self database] query:stmt];
    return [__ALResultSetEnumerator enumatorWithResultSet:rs modelClass:self resultColumns:resultColumns];
}

@end
