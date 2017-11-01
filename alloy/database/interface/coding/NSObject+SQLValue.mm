//
//  NSObject+SQLValue.m
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+SQLValue.h"
#import "ALLogger.h"

@implementation NSObject (SQLValue)

- (aldb::SQLValue)al_SQLValue {
    if (self == NSNull.null) {
        return aldb::SQLValue(nullptr);
        
    } else if ([self isKindOfClass:NSString.class]) {
        return aldb::SQLValue([(NSString *) self UTF8String]);
        
    } else if ([self isKindOfClass:NSNumber.class]) {
        NSNumber *obj = (NSNumber *) self;
        const char *type = obj.objCType;
        if (strcmp(type, @encode(BOOL))
            || strcmp(type, @encode(int8_t))
            || strcmp(type, @encode(int16_t))
            || strcmp(type, @encode(int32_t))
            || strcmp(type, @encode(uint8_t))
            || strcmp(type, @encode(uint16_t))
            || strcmp(type, @encode(uint32_t))) {
            // int32
            return aldb::SQLValue([obj intValue]);
        } else if (strcmp(type, @encode(int64_t)) || strcmp(type, @encode(uint64_t))) {
            // int64
            return aldb::SQLValue([obj longLongValue]);
        } else {
            return aldb::SQLValue([obj doubleValue]);
        }
    } else if ([self isKindOfClass:NSData.class]) {
        NSData *d = (NSData *) self;
        return aldb::SQLValue(d.bytes, d.length);
    } else if ([self isKindOfClass:NSDate.class]) {
        NSDate *d = (NSDate *) self;
        return aldb::SQLValue(d.timeIntervalSince1970);
    } else {
        @try {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
            return aldb::SQLValue(data.bytes, data.length);
        } @catch (NSException *exception) {
            ALLogWarn(@"Can NOT convert object:\"%@\" to SQL value, using \"NULL\" as default. Reason: %@", self,
                      exception);
            return aldb::SQLValue(nullptr);
        }
    }
}

@end
