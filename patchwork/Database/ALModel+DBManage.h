//
//  ALModel+DBManage.h
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel.h"
#import "ALDatabaseModelProtocol.h"


extern NSString * const kInMemoryDBPath;
extern NSString * const kTemporaryDBPath;

@class YYClassPropertyInfo;
extern NSString * suggestedSqliteDataType(YYClassPropertyInfo *property);

@interface ALModel (DBManage) <ALDatabaseModelProtocol>

+ (NSSet<NSString *> *)columnNames;
+ (BOOL)createIndexes:(FMDatabase *)db;

@end
