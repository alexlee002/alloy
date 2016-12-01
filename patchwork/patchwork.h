//
//  patchwork.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
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
#import "ALDBColumnInfo.h"
#import "ALDBConnectionProtocol.h"
#import "ALDBMigrationProtocol.h"
#import "ALDatabase.h"
#import "ALFMDatabaseQueue.h"
#import "ALSQLClause+SQLFunctions.h"
#import "ALSQLClause+SQLOperation.h"
#import "ALSQLClause.h"
#import "ALSQLCondition.h"
#import "ALSQLExpression.h"

// Database/SqlCommands
#import "ALSQLDeleteStatement.h"
#import "ALSQLInsertStatement.h"
#import "ALSQLSelectStatement.h"
#import "ALSQLStatement.h"
#import "ALSQLStatementHelpers.h"
#import "ALSQLUpdateStatement.h"

// Extensions
#import "BlocksKitExtension.h"
#import "NSArray+ArrayExtensions.h"
#import "NSCache+ALExtensions.h"
#import "NSDate+ALExtensions.h"
#import "NSString+Helper.h"
#import "URLHelper.h"

// Foundations
#import "ALDevice.h"
#import "ALLock.h"
#import "ALLogger.h"
#import "ALOCRuntime.h"
#import "ALOrderedMap.h"
#import "ALStringInflector.h"
#import "Base64.h"
#import "CRC.h"
#import "DES.h"
#import "HHTimer.h"
#import "MD5.h"
#import "NSObject+JSONTransform.h"
#import "RC4.h"
#import "SHA1.h"
#import "SafeBlocksChain.h"
#import "Singleton_Template.h"
#import "UtilitiesHeader.h"

// Model
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

