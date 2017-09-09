//
//  ALSQLValue.m
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLValue.h"
#import "ALSQLExpr.h"
#import "ALDBValueCoding.h"
#include <unordered_set>
#import <objc/message.h>

ALSQLValue::ALSQLValue(int32_t i32):_coreValue(i32) {};

ALSQLValue::ALSQLValue(int64_t i64):_coreValue(i64) {}

ALSQLValue::ALSQLValue(long l):_coreValue((int64_t)l) {}

ALSQLValue::ALSQLValue(double d): _coreValue(d) {}

ALSQLValue::ALSQLValue(BOOL b): _coreValue(b) {}

ALSQLValue::ALSQLValue(const std::string &s): _coreValue(s) {}

ALSQLValue::ALSQLValue(const char *c) :_coreValue(c) {}

ALSQLValue::ALSQLValue(const void *b, size_t size):_coreValue(b, size) {}

ALSQLValue::ALSQLValue(std::nullptr_t): _coreValue(nullptr) {}

ALSQLValue::ALSQLValue(const aldb::SQLValue &v): _coreValue(v) {}

//ALSQLValue::ALSQLValue(NSInteger i): _coreValue(sizeof(i) > 4 ? (int64_t)i : (int32_t)i) {}

//ALSQLValue::ALSQLValue(NSString *s):_coreValue(s.UTF8String) {};
//
//ALSQLValue::ALSQLValue(NSData *d) :_coreValue(d.bytes, d.length) {};
//
//ALSQLValue::ALSQLValue(NSDate *date) : _coreValue(date.timeIntervalSince1970) {};
//
//ALSQLValue::ALSQLValue(NSURL *url) : _coreValue(url.absoluteString.UTF8String) {};
//
//ALSQLValue::ALSQLValue(NSNumber *num) {
//    const char *type = num.objCType;
//    if (strcmp(type, @encode(BOOL))
//        //int32
//        || strcmp(type, @encode(int8_t))
//        || strcmp(type, @encode(int16_t))
//        || strcmp(type, @encode(int32_t))
//        || strcmp(type, @encode(uint8_t))
//        || strcmp(type, @encode(uint16_t))
//        || strcmp(type, @encode(uint32_t))
//        ) {
//        _coreValue = aldb::SQLValue([num intValue]);
//    } else if (
//        // int64
//        strcmp(type, @encode(int64_t)) || strcmp(type, @encode(uint64_t))
//        ) {
//        _coreValue = aldb::SQLValue([num longLongValue]);
//    } else if (strcmp(type, @encode(float)) || strcmp(type, @encode(double))) {
//        _coreValue = aldb::SQLValue([num doubleValue]);
//    }
//}

ALSQLValue::ALSQLValue(id obj) {
    if (obj == nil || obj == NSNull.null) {
        _coreValue = aldb::SQLValue(nullptr);
    } else {
        if ([(id)[obj class] respondsToSelector:@selector(al_valueByTransformingToDB)]) {
            _coreValue = ((aldb::SQLValue(*)(id, SEL))(void *)objc_msgSend)(obj, @selector(al_valueByTransformingToDB));
        }
        else if ([obj isKindOfClass:NSString.class]) {
            _coreValue = aldb::SQLValue([(NSString *)obj UTF8String]);
        }
        else if ([obj isKindOfClass:NSNumber.class]) {
            const char *type = ((NSNumber *)obj).objCType;
            if (strcmp(type, @encode(BOOL))
                //int32
                || strcmp(type, @encode(int8_t))
                || strcmp(type, @encode(int16_t))
                || strcmp(type, @encode(int32_t))
                || strcmp(type, @encode(uint8_t))
                || strcmp(type, @encode(uint16_t))
                || strcmp(type, @encode(uint32_t))
                ) {
                _coreValue = aldb::SQLValue([obj intValue]);
            } else if (strcmp(type, @encode(int64_t)) || strcmp(type, @encode(uint64_t))) {
                // int64
                _coreValue = aldb::SQLValue([obj longLongValue]);
            } else /*if (strcmp(type, @encode(float)) || strcmp(type, @encode(double)))*/ {
                _coreValue = aldb::SQLValue([obj doubleValue]);
            }
        }
        else if ([obj isKindOfClass:NSData.class]) {
            NSData *d = (NSData *)obj;
            _coreValue = aldb::SQLValue(d.bytes, d.length);
        }
        else if ([obj isKindOfClass:NSDate.class]) {
            NSDate *d = (NSDate *)obj;
            _coreValue = aldb::SQLValue(d.timeIntervalSince1970);
        }
        else {
            @try {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
                _coreValue = aldb::SQLValue(data.bytes, data.length);
            } @catch (NSException *exception) {
                ALLogError(@"%@", exception);
                _coreValue = aldb::SQLValue(nullptr);
            }
        }
    }
}

bool ALSQLValue::operator==(const ALSQLValue &o) const {
    return _coreValue == o._coreValue;
}

//ALSQLValue &ALSQLValue::operator=(const ALSQLValue &o) {
//    _coreValue = o._coreValue;
//    return *this;
//}

ALSQLValue::operator aldb::SQLValue() const {
    return _coreValue;
}

ALSQLValue::operator std::list<const aldb::SQLValue>() const {
    return {_coreValue};
}

ALSQLValue::operator std::list<const ALSQLValue>() const {
    return {*this};
}

ALSQLValue::operator ALSQLExpr() const {
    return ALSQLExpr(*this);
}
