//
//  ALSQLValue.h
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <string>
#import <list>
#import "sql_value.hpp"

extern "C" {
#import "ALLogger.h"
}

class ALSQLExpr;
class ALSQLValue {
public:
    //native value type
    ALSQLValue(int32_t v);
    ALSQLValue(int64_t v);
    ALSQLValue(long value);
    ALSQLValue(double v);
    ALSQLValue(BOOL v);
    ALSQLValue(const std::string &s);
    ALSQLValue(const char *value);
    ALSQLValue(const void *b, size_t size);
    ALSQLValue(std::nullptr_t);
    ALSQLValue(const aldb::SQLValue &v);

//    template <typename T>
//    ALSQLValue(const T &value,
//               typename std::enable_if</*std::is_arithmetic<T>::value || */std::is_enum<T>::value>::type * = nullptr)
//    : _coreValue(sizeof(value) > 4 ? (int64_t)value : (int32_t)(value)) {}

    //objc type
//    ALSQLValue(NSInteger i);
//    
//    ALSQLValue(NSString *s);
//    ALSQLValue(NSData *d);
//    ALSQLValue(NSDate *date);
//    ALSQLValue(NSURL *url);
//    ALSQLValue(NSNumber *num);
    
    ALSQLValue(id obj);

    template <typename T>
    ALSQLValue(const T &value,
               typename std::enable_if<std::is_same<T, NSRange>::value           ||
                                       std::is_same<T, CGSize>::value            ||
                                       std::is_same<T, CGPoint>::value           ||
                                       std::is_same<T, CGRect>::value            ||
                                       std::is_same<T, UIEdgeInsets>::value      ||
                                       std::is_same<T, UIOffset>::value          ||
                                       std::is_same<T, CGVector>::value          ||
                                       std::is_same<T, CGAffineTransform>::value ||
                                       std::is_same<T, CATransform3D>::value>::type * = nullptr) {
        NSValue *v = [NSValue value:&value withObjCType:@encode(T)];
        @try {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:v];
            _coreValue = aldb::SQLValue(data.bytes, data.length);
        } @catch (NSException *exception) {
            ALLogError(@"%@", exception);
        }
    }

//    ALSQLValue &operator=(const ALSQLValue &o);
    bool operator==(const ALSQLValue &o) const;
    operator aldb::SQLValue() const;
    operator std::list<const aldb::SQLValue>() const;
    operator std::list<const ALSQLValue>() const;
    operator ALSQLExpr() const;
protected:    
    aldb::SQLValue _coreValue;
};
