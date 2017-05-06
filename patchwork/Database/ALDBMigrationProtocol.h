//
//  ALDBMigrationProtocol.h
//  patchwork
//
//  Created by Alex Lee on 2/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@protocol ALDBMigrationProtocol <NSObject>

+ (BOOL)canMigrateDatabaseWithPath:(NSString *)path;
- (NSInteger)currentVersion;

- (BOOL)database:(FMDatabase *)dbHandler upgradeFromVersion:(NSInteger)fromVersion to:(NSInteger)toVersion;

- (BOOL)database:(FMDatabase *)dbHandler downgradeFromVersion:(NSInteger)fromVersion to:(NSInteger)toVersion;

@optional
- (BOOL)setupDatabase:(FMDatabase *)db;

@end
