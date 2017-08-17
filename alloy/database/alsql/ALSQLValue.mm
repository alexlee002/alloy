//
//  ALSQLValue.m
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLValue.h"
#include <unordered_set>

//ALSQLValue::ALSQLValue(const int32_t i32):_coreValue(i32) {};
//
//ALSQLValue::ALSQLValue(const int64_t i64):_coreValue(i64) {}

//ALSQLValue::ALSQLValue(const double   d): _coreValue(d) {}

ALSQLValue::ALSQLValue(const std::string &s): _coreValue(s) {}

//ALSQLValue::ALSQLValue(const char *c) :_coreValue(c) {}

ALSQLValue::ALSQLValue(const void *b, size_t size):_coreValue(b, size) {}

ALSQLValue::ALSQLValue(const std::nullptr_t): _coreValue(nullptr) {}

//ALSQLValue::ALSQLValue(NSInteger i): _coreValue(sizeof(i) > 4 ? (int64_t)i : (int32_t)i) {}

ALSQLValue::ALSQLValue(NSString *s):_coreValue(s.UTF8String) {};

ALSQLValue::ALSQLValue(NSData *d) :_coreValue(d.bytes, d.length) {};

ALSQLValue::ALSQLValue(NSDate *date) : _coreValue(date.timeIntervalSince1970) {};

ALSQLValue::ALSQLValue(NSURL *url) : _coreValue(url.absoluteString.UTF8String) {};

ALSQLValue::ALSQLValue(NSNumber *num) {
    const char *type = num.objCType;
    if (strcmp(type, @encode(BOOL))
        //int32
        || strcmp(type, @encode(int8_t))
        || strcmp(type, @encode(int16_t))
        || strcmp(type, @encode(int32_t))
        || strcmp(type, @encode(uint8_t))
        || strcmp(type, @encode(uint16_t))
        || strcmp(type, @encode(uint32_t))
        ) {
        _coreValue = aldb::SQLValue([num intValue]);
    } else if (
        // int64
        strcmp(type, @encode(int64_t)) || strcmp(type, @encode(uint64_t))
        ) {
        _coreValue = aldb::SQLValue([num longLongValue]);
    } else if (strcmp(type, @encode(float)) || strcmp(type, @encode(double))) {
        _coreValue = aldb::SQLValue([num doubleValue]);
    }
}

ALSQLValue::ALSQLValue(id obj) {
    @try {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
        _coreValue = aldb::SQLValue(data.bytes, data.length);
    } @catch (NSException *exception) {
        ALLogError(@"%@", exception);
    }
}

ALSQLValue::operator aldb::SQLValue() const {
    return _coreValue;
}

ALSQLValue::operator std::list<const aldb::SQLValue>() {
    return {_coreValue};
}
