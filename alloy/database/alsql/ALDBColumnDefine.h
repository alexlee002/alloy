//
//  ALDBColumnDefine.h
//  alloy
//
//  Created by Alex Lee on 16/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBColumn.h"
#import "ALDBTypeDefs.h"
#import "ALSQLClause.h"

class ALSQLExpr;
class ALSQLValue;
class ALDBColumnDefine {
public:
    ALDBColumnDefine(const ALDBColumn &column, ALDBColumnType type);
    ALDBColumnDefine(const ALDBColumn &column, const std::string &type_name);
    operator ALSQLClause() const;
    
    ALDBColumnDefine &as_primary(ALDBOrder order_term = ALDBOrderDefault,
                                 ALDBConflictPolicy on_conflict = ALDBConflictPolicyDefault,
                                 bool auto_increment = false);
    
    ALDBColumnDefine &as_unique(ALDBConflictPolicy on_conflict = ALDBConflictPolicyDefault);
    ALDBColumnDefine &not_null(ALDBConflictPolicy on_conflict = ALDBConflictPolicyDefault);
    ALDBColumnDefine &default_value(const ALSQLExpr &expr);
    ALDBColumnDefine &default_value(const ALSQLValue &value);
    ALDBColumnDefine &default_value(ALDBDefaultTime time_value);
    ALDBColumnDefine &collate(const std::string &name);
    ALDBColumnDefine &check(const ALSQLExpr &expr);
    
    const ALDBColumn &column() const;
    ALDBColumnType column_type() const;
    const std::string &type_name() const;
    NSString *_Nonnull typeName();
    
    bool auto_increment() const;
    bool is_primary() const;
    bool is_unique() const;
    
private:
    ALDBColumn _column;
    ALDBColumnType _type;
    std::string _type_name;
    ALSQLClause _constraints;
    
    bool _auto_increment;
    bool _primary;
    bool _unique;
};
