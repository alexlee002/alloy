//
//  ALSQLClause.m
//  alloy
//
//  Created by Alex Lee on 15/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"
#import "ALSQLValue.h"

ALSQLClause::ALSQLClause() {}
ALSQLClause::ALSQLClause(std::nullptr_t) {}
ALSQLClause::ALSQLClause(const char *_Nonnull sql) : _sql(sql ? sql : "") {}

ALSQLClause::ALSQLClause(const std::string &sql) : _sql(sql) {}
ALSQLClause::ALSQLClause(const std::string &sql, const std::list<const ALSQLValue> &args) : _sql(sql), _args(args) {}

ALSQLClause::ALSQLClause(NSString *_Nonnull sql) : _sql(sql ? sql.UTF8String : "") {}
ALSQLClause::ALSQLClause(NSString *_Nonnull sql, NSArray<id> *_Nonnull args) : _sql(sql ? sql.UTF8String : "") {
    for (id arg in args) {
        _args.push_back(ALSQLValue(arg));
    }
}

ALSQLClause::ALSQLClause(const ALSQLClause &clause) : _sql(clause._sql), _args(clause._args) {}

ALSQLClause &ALSQLClause::append(const std::string &sql, const std::list<const ALSQLValue> &args) {
    _sql.append(sql);
    _args.insert(_args.end(), args.begin(), args.end());
    return *this;
}

ALSQLClause &ALSQLClause::append(NSString *_Nonnull sql) {
    if (sql.length > 0) {
        _sql.append(sql.UTF8String);
    }
    return *this;
}

ALSQLClause &ALSQLClause::append(const ALSQLClause &clause) {
    return append(clause.sql_str(), clause.sqlArgs());
}

//ALSQLClause &ALSQLClause::operator+=(const ALSQLClause &clause) { return *this; }
//
//ALSQLClause ALSQLClause::operator+(const ALSQLClause &other) const {
//    ALSQLClause clause(*this);
//    return clause.append(other);
//}

const std::string &ALSQLClause::sql_str() const { return _sql; }

const std::list<const aldb::SQLValue> ALSQLClause::sql_args() const {
    std::list<const aldb::SQLValue> core_args;
    for (auto t : _args) {
        core_args.push_back(aldb::SQLValue(t));
    }
    return core_args;
}

NSString *_Nonnull ALSQLClause::sqlString() { return @(_sql.c_str()); }

const std::list<const ALSQLValue> &ALSQLClause::sqlArgs() const { return _args; }

bool ALSQLClause::is_empty() const { return _sql.empty(); }
