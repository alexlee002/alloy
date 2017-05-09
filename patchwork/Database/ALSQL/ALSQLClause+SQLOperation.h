//
//  ALSQLClause+SQLOperation.h
//  patchwork
//
//  Created by Alex Lee on 16/10/13.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSInteger kALSQLOperatorPrecedenceUninitialized;
//return the precedence of the operator or kALSQLOperatorPrecedenceUninitialized if unknown.
extern NSInteger sql_operator_precedence(NSString *optr);
extern ALSQLClause *sql_op_mid  (ALSQLClause *src,    NSString    *optor,  NSInteger precedence, ALSQLClause *other);
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
@property(readonly, copy) ALSQLClause *(^SQL_NOT_IN)(id obj);

@property(readonly, copy) ALSQLClause *(^SQL_LIKE)(id obj);
// PREFIX_LIKE(xxx) => "LIKE xxx%"
@property(readonly, copy) ALSQLClause *(^SQL_PREFIX_LIKE)(id obj);
// SUBFIX_LIKE(xxx) => "LIKE %xxx"
@property(readonly, copy) ALSQLClause *(^SQL_SUBFIX_LIKE)(id obj);

// NOT operation,
//  eg: #1
//      XCTAssertEqualObjects(@"col1".SQL_EQ(@1).SQL_NOT().SQLString, @"NOT (col1 = ?)");
//
//  eg: #2
//      sql = @"col1".SQL_EQ(@1).SQL_AND(@"col2".SQL_PREFIX_LIKE(@"abc").SQL_NOT());
//      XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND NOT (col2 LIKE ?)");
@property(readonly, copy) ALSQLClause *(^SQL_NOT)   ();

@property(readonly, copy) ALSQLClause *(^SQL_IS)    (id obj);
@property(readonly, copy) ALSQLClause *(^SQL_IS_NOT)(id obj);

//eg:
//  @"col".SQL_ISNULL() => (col) IS NULL
//  @"col1".SQL_EQ(@1).SQL_AND(@"col2").ISNULL() => (col1 = 1 AND col2) IS NULL
//  @"col1".SQL_EQ(@1).SQL_AND(@"col2".ISNULL()) => col1 = 1 AND (col2) IS NULL
@property(readonly, copy) ALSQLClause *(^SQL_ISNULL)();
@property(readonly, copy) ALSQLClause *(^SQL_NOTNULL)();

//"x BETWEEN y AND z" is equivalent to "x>=y AND x<=z" except that with BETWEEN, the x expression is only evaluated once
//The precedence of the BETWEEN operator is the same as the precedence as operators == and != and LIKE and groups left to right.
@property(readonly, copy) ALSQLClause *(^SQL_BETWEEN)(id x, id y);
@property(readonly, copy) ALSQLClause *(^SQL_ESCAPE)(id exp);
@property(readonly, copy) ALSQLClause *(^SQL_COLLATE)(id exp);

// ORDER BY
@property(readonly, copy) ALSQLClause *(^SQL_ASC)();
@property(readonly, copy) ALSQLClause *(^SQL_DESC)();

@property(readonly, copy) ALSQLClause *(^SQL_AS)(NSString *alias);

@end


@interface ALSQLClause (AL_Common_sqlClauses)

//http://www.sqlite.org/lang_expr.html
//CASE x WHEN w1 THEN r1 WHEN w2 THEN r2 ELSE r3 END
//CASE WHEN x=w1 THEN r1 WHEN x=w2 THEN r2 ELSE r3 END
+ (ALSQLClause *)sql_case:(nullable id)c when:(id)w then:(id)t else:(nullable id)z;
- (ALSQLClause *)sql_when:(id)y then:(id)t else:(id)z;
- (ALSQLClause *)sql_when:(id)y then:(id)t;
- (ALSQLClause *)sql_case_end;
@end
NS_ASSUME_NONNULL_END
