//
//  ALDBConnectionProtocol.h
//  patchwork
//
//  Created by Alex Lee on 16/10/11.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@protocol ALDBConnectionProtocol <NSObject>

+ (BOOL)canHandleDatabaseWithPath:(NSString *)path;

@optional
- (void)databaseDidOpen:(FMDatabase *)db;
- (void)databaseDidReady:(FMDatabase *)db;

- (void)databaseWillClose:(FMDatabase *)db;
- (void)databaseWithPathDidClose:(NSString *)dbpath;
@end
