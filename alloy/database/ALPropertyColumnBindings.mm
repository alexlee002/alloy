//
//  ALPropertyColumnBindings.m
//  alloy
//
//  Created by Alex Lee on 22/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALPropertyColumnBindings.h"
#import "__ALPropertyColumnBindings+private.h"
#import "ALDBTypeCoding.h"
#import "ALSQLValue.h"
#import "ALUtilitiesHeader.h"
#import "ALDBValueCoding.h"
#import "ALActiveRecord.h"
#import <unordered_map>
#import <string>
#import <objc/message.h>


AL_FORCE_INLINE ALDBColumnType columnTypeForProperty(_ALModelPropertyMeta *property);

@implementation ALPropertyColumnBindings

+ (instancetype)bindingWithModel:(Class)modelClass
                    propertyMeta:(_ALModelPropertyMeta *)meta
                          column:(NSString *)columnName {
    
    ALPropertyColumnBindings *bindings = [[self alloc] init];
    bindings->_cls = modelClass;
    bindings->_propertyMeta = meta;
    bindings->_colName   = [columnName copy];
    ALDBColumnType colType  = columnTypeForProperty(meta);
    bindings->_columnDef =
        std::shared_ptr<ALDBColumnDefine>(new ALDBColumnDefine(ALDBColumn(columnName.UTF8String), colType));

    if ([(id) modelClass respondsToSelector:@selector(customDefineColumn:forProperty:)]) {
        ((void (*)(id, SEL, ALDBColumnDefine, id /*YYClassPropertyInfo*/))(void *) objc_msgSend)(
            (id) modelClass, @selector(customDefineColumn:forProperty:), *(bindings->_columnDef), meta->_info);
    }
    return bindings;
}

- (YYClassPropertyInfo *)propertyInfo {
    return _propertyMeta->_info;
}

- (const ALDBColumnDefine &)columnDefine {
    return *_columnDef;
}

- (NSString *)columnName {
    return _colName;
}

- (NSString *)propertyName {
    return _propertyMeta->_name;
}

- (SEL)customPropertyValueFromColumnTransformer {
    return _customSetter;
}

- (SEL)customPropertyValueToColumnTransformer {
    return _customGetter;
}

@end

AL_FORCE_INLINE BOOL columnTypeForCType(YYEncodingType ctype, ALDBColumnType *colType) {
    if (!colType) {
        return NO;
    }
    static const std::unordered_map<long, uint8_t> CTypesMap = {
        {YYEncodingTypeBool,    ALDBColumnTypeInt},     ///< bool
        {YYEncodingTypeInt8,    ALDBColumnTypeInt},     ///< char / BOOL
        {YYEncodingTypeUInt8,   ALDBColumnTypeInt},     ///< unsigned char
        {YYEncodingTypeInt16,   ALDBColumnTypeInt},     ///< short
        {YYEncodingTypeUInt16,  ALDBColumnTypeInt},     ///< unsigned short
        {YYEncodingTypeInt32,   ALDBColumnTypeInt},     ///< int
        {YYEncodingTypeUInt32,  ALDBColumnTypeInt},     ///< unsigned int
        //--------------------
        {YYEncodingTypeInt64,   ALDBColumnTypeLong},    ///< long long
        {YYEncodingTypeUInt64,  ALDBColumnTypeLong},    ///< unsigned long long
        //--------------------
        {YYEncodingTypeFloat,       ALDBColumnTypeDouble},  ///< float
        {YYEncodingTypeDouble,      ALDBColumnTypeDouble},  ///< double
        {YYEncodingTypeLongDouble,  ALDBColumnTypeDouble},  ///< long double
        //--------------------
        {YYEncodingTypeCString, ALDBColumnTypeText},    ///< char *
        {YYEncodingTypeSEL,     ALDBColumnTypeText},
        {YYEncodingTypeClass,   ALDBColumnTypeText},
    };
    
    auto iter = CTypesMap.find(ctype & YYEncodingTypeMask);
    if (iter != CTypesMap.end()) {
        *colType = (ALDBColumnType)iter->second;
        return YES;
    }
    return NO;
}

AL_FORCE_INLINE ALDBColumnType columnTypeForProperty(_ALModelPropertyMeta *property) {
    
    if ((property->_type & YYEncodingTypeMask) == YYEncodingTypeObject) {
        if ([(id)property->_cls respondsToSelector:@selector(ALDBColumnType)]) {
            return ((ALDBColumnType(*)(id, SEL))(void *)objc_msgSend)((id)property->_cls, @selector(ALDBColumnType));
        }

        static const std::unordered_map<long, uint8_t> NSTypesMap = {
            {YYEncodingTypeNSString,        ALDBColumnTypeText},
            {YYEncodingTypeNSMutableString, ALDBColumnTypeText},
            {YYEncodingTypeNSURL,           ALDBColumnTypeText},
            {YYEncodingTypeNSNumber,        ALDBColumnTypeDouble},
            {YYEncodingTypeNSDecimalNumber, ALDBColumnTypeDouble},
            {YYEncodingTypeNSDate,          ALDBColumnTypeDouble},
        };
        
        auto iter = NSTypesMap.find(property->_nsType);
        if (iter != NSTypesMap.end()) {
            return (ALDBColumnType)iter->second;
        }
    } else {
        ALDBColumnType colType;
        if (columnTypeForCType(property->_type, &colType)) {
            return colType;
        }
        
        const char *propertyEncoding = property->_info.typeEncoding.UTF8String;
        if (strcmp(propertyEncoding, @encode(std::string)) == 0 ||
            strcmp(propertyEncoding, @encode(const std::string)) == 0) {
            return ALDBColumnTypeText;
        }
    }
    return ALDBColumnTypeBlob;
}


