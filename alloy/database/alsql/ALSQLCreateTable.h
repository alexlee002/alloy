//
//  ALSQLCreateTable.h
//  alloy
//
//  Created by Alex Lee on 26/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALDBColumnDefine.h"
#import "ALDBTableConstraint.h"

@interface ALSQLCreateTable : ALSQLStatement

- (instancetype)createTable:(NSString *)table;
- (instancetype)createTable:(NSString *)table ifNotExists:(BOOL)ifNotExists isTemperate:(BOOL)isTmpTable;

- (instancetype)columnDefines:(const std::list<const ALDBColumnDefine> &)columnDefs;

- (instancetype)constraints:(const std::list<const ALDBTableConstraint> &)constraints;
- (instancetype)withoutRowId:(BOOL)yesOrNo;

@end
