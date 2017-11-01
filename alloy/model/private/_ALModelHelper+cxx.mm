//
//  _ALModelHelper+cxx.m
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "_ALModelHelper+cxx.h"
#import "ALMacros.h"
#import "ALDBColumnBinding_Private.h"
#import "ALLogger.h"
#import "NSObject+AL_Database.h"
#import <objc/message.h>

id _Nullable _ALColumnValueForModelProperty(id _Nonnull model, ALDBColumnBinding *_Nonnull binding) {
    NSString *propertyName = [binding propertyName];
    if (propertyName == nil) {
        return nil;
    }

    _ALModelPropertyMeta *propertyInfo = binding->_propertyMeta;
    SEL getter = [binding customPropertyValueGetter];
    if (getter) {
        return ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
    }

    getter = propertyInfo->_getter;

    switch (propertyInfo->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;

        case YYEncodingTypeInt8: {
            int8_t num = ((int8_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeUInt8: {
            uint8_t num = ((uint8_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;

        case YYEncodingTypeInt16: {
            int16_t num = ((int16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeUInt16: {
            uint16_t num = ((uint16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;

        case YYEncodingTypeInt32: {
            int32_t num = ((int32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeUInt32: {
            uint32_t num = ((uint32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;

        case YYEncodingTypeInt64: {
            int64_t num = ((int64_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;

        case YYEncodingTypeUInt64: {
            uint64_t num = ((uint64_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeLongDouble: {
            long double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
#ifdef DEBUG
            if (num != (double) num) {
                ALLogError(@"accuracy lost from (long double) to (double)");
            }
#endif
            return @((double) num);
        } break;

        case YYEncodingTypeObject: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return value;
        } break;

        case YYEncodingTypeClass:
        case YYEncodingTypeBlock: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return value;
        } break;
        case YYEncodingTypeSEL:
        case YYEncodingTypePointer:
        case YYEncodingTypeCString: {
            size_t value = ((size_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return [NSValue valueWithPointer:*((SEL *) value)];
        } break;
        case YYEncodingTypeStruct:
        case YYEncodingTypeUnion: {
            @try {
                NSValue *value = [(id) model valueForKey:NSStringFromSelector(getter)];
                return value;
            } @catch (NSException *exception) {
                ALLogWarn(@"%@", exception);
            }
        } break;

        default:
            ALLogWarn(@"Getter: \"%@\" not found for property:\"%@\"", NSStringFromSelector(getter),
                      propertyInfo->_name);
            break;
    }
    return nil;
}

//id _Nullable _ALColumnValueForModelProperty(id _Nonnull model, ALDBColumnBinding *_Nonnull binding) {
//    id value = nil;
//    if (![model al_autoIncrement] || !_ALISAutoIncrementColumn(binding)) {
//        value = __AL_ColumnValueForModelProperty(model, binding);
//    }
//    return value;
//}

BOOL _ALISAutoIncrementColumn(ALDBColumnBinding *binding) {
    ALDBTableBinding *tableBindings = [binding.modelClass al_tableBindings];
    if (tableBindings == nil) {
        return NO;
    }
    
    return [tableBindings.allPrimaryKeys isEqualToArray:@[ [binding propertyName] ]] &&
           (binding.columnType == ALDBColumnTypeInt || binding.columnType == ALDBColumnTypeLong);
}
