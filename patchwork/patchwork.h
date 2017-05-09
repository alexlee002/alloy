//
//  patchwork.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <Foundation/Foundation.h>

//! Project version number for patchwork.
FOUNDATION_EXPORT double patchworkVersionNumber;

//! Project version string for patchwork.
FOUNDATION_EXPORT const unsigned char patchworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <patchwork/patchwork.h>

// Database
#import "ALDBConnectionProtocol.h"
#import "ALDBMigrationHelper.h"
#import "ALDBMigrationProtocol.h"
#import "ALDatabase.h"
#import "ALFMDatabaseQueue.h"

// Database/ALSQL
#import "ALDatabaseValueTransformProtocol.h"
#import "ALSQLClause+SQLFunctions.h"
#import "ALSQLClause+SQLOperation.h"
#import "ALSQLClause.h"

// Database/ALSQL/SqlStatements
#import "ALSQLDeleteStatement.h"
#import "ALSQLInsertStatement.h"
#import "ALSQLSelectStatement.h"
#import "ALSQLStatement.h"
#import "ALSQLUpdateStatement.h"

// Extensions
#import "BlocksKitExtension.h"
#import "NSArray+ArrayExtensions.h"
#import "NSBundle+BundleInfo.h"
#import "NSCache+ALExtensions.h"
#import "NSDate+ALExtensions.h"
#import "NSString+ALHelper.h"
#import "AL_URLHelper.h"

// Foundations
#import "ALAssociatedWeakObject.h"
#import "ALDevice.h"
#import "ALLock.h"
#import "ALLogger.h"
#import "ALOCRuntime.h"
#import "ALOrderedMap.h"
#import "ALStringInflector.h"
#import "ALUtilitiesHeader.h"
#import "AL_Base64.h"
#import "AL_CRC.h"
#import "AL_DES.h"
#import "AL_JSON.h"
#import "AL_MD5.h"
#import "AL_RC4.h"
#import "AL_SHA1.h"
#import "HHTimer.h"
#import "SafeBlocksChain.h"
#import "Singleton_Template.h"

// Model
#import "ALDBColumnInfo.h"
#import "ALModel+ActiveRecord.h"
#import "ALModel+JSON.h"
#import "ALModel.h"
#import "ALModel_Define.h"
#import "ActiveRecordAdditions.h"

// NetworkAdaptor
#import "ALHTTPRequest+Helper.h"
#import "ALHTTPRequest.h"
#import "ALHTTPResponse.h"
#import "ALNetwork_config.h"
#import "ALURLRequestQueueAdaptorProtocol.h"
#import "ASIHTTPRequestQueueAdaptor.h"
#import "NSURLSessionAdaptor.h"

