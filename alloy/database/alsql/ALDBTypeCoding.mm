//
//  ALDBTypeCoding.m
//  alloy
//
//  Created by Alex Lee on 05/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBTypeCoding.h"
#import <unordered_set>
#import <string>

@implementation ALDBTypeCoding

+ (ALDBColumnType)columnTypeForObjCType:(const char *)objcTypeEncode {
    static const std::unordered_set<const char *> int32_types = {
        @encode(int8_t),
        @encode(uint8_t),
        @encode(char),
        @encode(char16_t),
        @encode(char32_t),
        @encode(int16_t),
        @encode(uint16_t),
        @encode(int32_t),
        @encode(uint32_t)
    };

    static const std::unordered_set<const char *> int64_types = {
        @encode(int64_t),
        @encode(uint16_t),
        @encode(long),
        @encode(unsigned long),
        @encode(long long),
        @encode(unsigned long long)
    };
    
    static const std::unordered_set<const char *> double_types = {
        @encode(float), @encode(double), @encode(long double)
    };

    static const std::unordered_set<const char *> text_types = {
        @encode(char *),
        @encode(const char *),
        @encode(std::string),
        @encode(const std::string),
        @encode(NSString *),
        @encode(NSURL *)
    };
    
#define isType(types) (types).find(objcTypeEncode) != (types).end()
    
    if (isType(int32_types)) {
        return ALDBColumnTypeInt;
    }
    if (isType(int64_types)) {
        return ALDBColumnTypeLong;
    }
    if (isType(double_types)) {
        return ALDBColumnTypeDouble;
    }
    if (isType(text_types)) {
        return ALDBColumnTypeText;
    }
    return ALDBColumnTypeBlob;
}

@end
