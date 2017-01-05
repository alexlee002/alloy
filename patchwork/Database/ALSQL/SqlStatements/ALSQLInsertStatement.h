//
//  ALSQLInsertStatement.h
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"


NS_ASSUME_NONNULL_BEGIN

/**
 * @see http://www.sqlite.org/lang_insert.html
 */
@interface ALSQLInsertStatement : ALSQLStatement

@property(readonly, copy) ALSQLInsertStatement *(^INSERT)       ();
@property(readonly, copy) ALSQLInsertStatement *(^REPLACE)      ();
@property(readonly, copy) ALSQLInsertStatement *(^OR_REPLACE)   (BOOL yesOrno);
@property(readonly, copy) ALSQLInsertStatement *(^OR_ROLLBACK)  (BOOL yesOrno);
@property(readonly, copy) ALSQLInsertStatement *(^OR_ABORT)     (BOOL yesOrno);
@property(readonly, copy) ALSQLInsertStatement *(^OR_FAIL)      (BOOL yesOrno);
@property(readonly, copy) ALSQLInsertStatement *(^OR_IGNORE)    (BOOL yesOrno);

@property(readonly, copy) ALSQLInsertStatement *(^INTO)         (NSString *table);
// values {column-name: SQLObject}; SQLObject shuould be ALSQLClause / NSString, NSNumber or other NSObject that responeds to 'stringValue' selector
@property(readonly, copy) ALSQLInsertStatement *(^VALUES_DICT)  (NSDictionary<NSString *, id> *values);

@property(readonly, copy) ALSQLInsertStatement *(^COLUMNS)      (NSArray<NSString *> *_Nullable columnNames);

// items in values shuould be ALSQLClause / NSString, NSNumber or other NSObject that responeds to 'stringValue' selector
@property(readonly, copy) ALSQLInsertStatement *(^VALUES)       (NSArray *values);
@property(readonly, copy) ALSQLInsertStatement *(^DEFAULT_VALUES)();
@property(readonly, copy) ALSQLInsertStatement *(^SELECT_STMT)  (ALSQLClause *selectClause);
@end

NS_ASSUME_NONNULL_END
