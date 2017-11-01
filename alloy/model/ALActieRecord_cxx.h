//
//  ALActieRecord_cxx.h
//  alloy
//
//  Created by Alex Lee on 25/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALActiveRecord.h"
#import "ALDBTypeDefines.h"
#import "YYClassInfo.h"

@protocol ALActieRecord_cxx <ALActiveRecord>
/**
 * Custom define a column. eg: PRIMARY KEY, AUTOINCREMENT, DEFAULT VALUE, COLLATE, ...
 *
 * DO NOT define UNIQUE column constraints here.  DO IT in "+uniqueKeys" or "+customTableIndexes",
 * so we can easier to merge the indexes while migrating the table.
 */
+ (void)customDefineColumn:(ALDBColumnDef &)cloumn forProperty:(YYClassPropertyInfo *_Nonnull)property;

/**
 * Custom define indexes.
 *
 * The index-name should be: {table_name}_{index_name}
 */
+ (const std::list<const ALDBIndex>)customTableIndexes;

@end
