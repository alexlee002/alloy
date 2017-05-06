//
//  ALSQLClause+SQLOperation.h
//  patchwork
//
//  Created by Alex Lee on 16/10/13.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"

NS_ASSUME_NONNULL_BEGIN

extern ALSQLClause *sql_op_mid  (ALSQLClause *src,    NSString    *optor,  NSInteger priority, ALSQLClause *other);
extern ALSQLClause *sql_op_left (NSString    *optor,  ALSQLClause *src); //???: sql function?
extern ALSQLClause *sql_op_right(ALSQLClause *src,    NSString    *optor);

@interface NSObject (SQLOperation)

@property(readonly, copy) ALSQLClause *(^SQL_AND)(id obj);
@property(readonly, copy) ALSQLClause *(^SQL_OR) (id obj);

@property(readonly, copy) ALSQLClause *(^SQL_EQ) (id obj);
@property(readonly, copy) ALSQLClause *(^SQL_LT) (id obj);
@property(readonly, copy) ALSQLClause *(^SQL_GT) (id obj);
@property(readonly, copy) ALSQLClause *(^SQL_IN) (id obj);

@property(readonly, copy) ALSQLClause *(^SQL_NEQ) (id obj);
@property(readonly, copy) ALSQLClause *(^SQL_NLT) (id obj);
@property(readonly, copy) ALSQLClause *(^SQL_NGT) (id obj);

@property(readonly, copy) ALSQLClause *(^SQL_LIKE)(id obj);
// PREFIX_LIKE(xxx) => "LIKE xxx%"
@property(readonly, copy) ALSQLClause *(^SQL_PREFIX_LIKE)(id obj);
// SUBFIX_LIKE(xxx) => "LIKE %xxx"
@property(readonly, copy) ALSQLClause *(^SQL_SUBFIX_LIKE)(id obj);



// just append 'NOT' keyword
//  eg: @"c2".SQL_NOT().SQL_LIKE(@"a%") => c2 NOT LIKE ?
//  eg: @"c2".SQL_NOT().IN(@1, @2) => c2 not in (?, ?)
// NOTE: if you want to join a "NOT" clause, use C function "SQL_NOT(id)"
// c1 = ? AND NOT (c2 = ? OR c2 = ?): @"c1".SQL_EQ(@1).AND(SQL_NOT(@"c2".SQL_EQ(@2).OR(@"c2".SQL_EQ(@3))))
@property(readonly, copy) ALSQLClause *(^SQL_NOT)();
@property(readonly, copy) ALSQLClause *(^SQL_NOT_IN)(id obj);
@property(readonly, copy) ALSQLClause *(^SQL_IS)();
@property(readonly, copy) ALSQLClause *(^SQL_IS_NOT)();

//eg:
//  @"col".SQL_ISNULL() => (col) IS NULL
//  @"col1".SQL_EQ(@1).SQL_AND(@"col2").ISNULL() => (col1 = 1 AND col2) IS NULL
//  @"col1".SQL_EQ(@1).SQL_AND(@"col2".ISNULL()) => col1 = 1 AND (col2) IS NULL
@property(readonly, copy) ALSQLClause *(^SQL_ISNULL)();
@property(readonly, copy) ALSQLClause *(^SQL_NOTNULL)();

//@property(readonly, copy) ALSQLClause *(^SQL_NLT)(id obj);
//@property(readonly, copy) ALSQLClause *(^SQL_NEQ)(id obj);
//@property(readonly, copy) ALSQLClause *(^SQL_NGT)(id obj);

// ORDER BY
@property(readonly, copy) ALSQLClause *(^SQL_ASC)();
@property(readonly, copy) ALSQLClause *(^SQL_DESC)();

@property(readonly, copy) ALSQLClause *(^SQL_AS)(NSString *alias);



// CASE a WHEN b THEN c ELSE d END
// eg: select case c2 when 'aa' then 1 else 2 end from test;
//@property(readonly, copy) ALSQLClause *(^SQL_CASE)(id _Nullable obj);
//@property(readonly, copy) ALSQLClause *(^SQL_WHEN)(id obj);
//@property(readonly, copy) ALSQLClause *(^SQL_THEN)(id obj);
//@property(readonly, copy) ALSQLClause *(^SQL_ELSE)(id obj);
//@property(readonly, copy) ALSQLClause *(^SQL_END)();
//+(ALSQLClause *)SQLCase:(id _Nullable)obj;
@end


@interface ALSQLClause (AL_Common_sqlClauses)
//http://www.sqlite.org/lang_expr.html
//CASE x WHEN w1 THEN r1 WHEN w2 THEN r2 ELSE r3 END
//CASE WHEN x=w1 THEN r1 WHEN x=w2 THEN r2 ELSE r3 END
+ (ALSQLClause *)sql_case:(nullable id)x when:(id)w then:(id)t else:(id)z;
- (ALSQLClause *)case_when:(id)y then:(id)t else:(id)z;
- (ALSQLClause *)case_when:(id)y then:(id)t;
- (ALSQLClause *)case_else:(id)z;
- (ALSQLClause *)case_end;
@end
NS_ASSUME_NONNULL_END
