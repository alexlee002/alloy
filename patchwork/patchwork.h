//
//  patchwork.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#if __has_include(<patchwork/patchwork.h>)
//! Project version number for patchwork.
FOUNDATION_EXPORT double patchworkVersionNumber;

//! Project version string for patchwork.
FOUNDATION_EXPORT const unsigned char patchworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <patchwork/PublicHeader.h>

#import <patchwork/ALDatabase.h>
#import <patchwork/ALDBMigrationProtocol.h>
#import <patchwork/ALFMDatabaseQueue.h>
#import <patchwork/ALDBColumnInfo.h>
#import <patchwork/ALSQLCondition.h>
#import <patchwork/NSArray+ArrayExtensions.h>
#import <patchwork/BlocksKitExtension.h>
#import <patchwork/NSString+Heler.h>
#import <patchwork/ALModel.h>
#else
#import "ALDatabase.h"
#import "ALDBMigrationProtocol.h"
#import "ALFMDatabaseQueue.h"
#import "ALDBColumnInfo.h"
#import "ALSQLCondition.h"
#import "NSArray+ArrayExtensions.h"
#import "BlocksKitExtension.h"
#import "NSString+Heler.h"
#import "ALModel.h"
#endif



