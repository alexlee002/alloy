//
//  ALDBColumnBinding.m
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBColumnBinding_Private.h"
#import "ALMacros.h"
#import "ALActiveRecord.h"
#import "NSString+ALHelper.h"
#import "column.hpp"
#import <objc/message.h>
#import <unordered_map>

static AL_FORCE_INLINE aldb::ColumnType columnTypeForProperty(_ALModelPropertyMeta *property);

@implementation ALDBColumnBinding

+ (instancetype)bindingWithModelMeta:(_ALModelMeta *)modelMeta
                        propertyMeta:(_ALModelPropertyMeta *)propertyMeta
                              column:(NSString *)columnName {
    ALParameterAssert(modelMeta);
    ALParameterAssert(propertyMeta);
    ALParameterAssert(columnName);

    ALDBColumnBinding *bindings = [[self alloc] init];

    bindings->_cls          = modelMeta->_info.cls;
    bindings->_propertyMeta = propertyMeta;
    bindings->_columnName   = [columnName copy];

    NSString *tmpPN = [propertyMeta->_name al_stringbyUppercaseFirst];
    //+ (id)customGetColumnValueFor{PropertyName};
    NSString *selName     = [@"customGetColumnValueFor" stringByAppendingString:tmpPN];
    NSDictionary *methods = modelMeta->_info.methodInfos;
    if (methods[selName]) {
        bindings->_customGetter = NSSelectorFromString(selName);
    }

    //- (void)customSet{PropertyName}WithColumnValue:(id)value;
    selName = [NSString stringWithFormat:@"customSet%@WithColumnValue:", tmpPN];
    if (methods[selName]) {
        bindings->_customSetter = NSSelectorFromString(selName);
    }

    aldb::ColumnType colType = aldb::ColumnType::BLOB_T;
    //- (ALDBColumnType)customColumnTypeFor{PropertyName};
    selName = [NSString stringWithFormat:@"customColumnTypeFor%@", tmpPN];
    if (methods[selName]) {
        colType =
            ((aldb::ColumnType(*)(id, SEL))(void *) objc_msgSend)((id) bindings->_cls, NSSelectorFromString(selName));
    } else {
        colType = columnTypeForProperty(propertyMeta);
    }

    bindings->_columnType = (ALDBColumnType)colType;
    bindings->_columnDef = std::shared_ptr<aldb::ColumnDef>(new aldb::ColumnDef(columnName.UTF8String, colType));

    SEL customColDef = @selector(customDefineColumn:forProperty:);
    if ([(id) bindings->_cls respondsToSelector:customColDef]) {
        ((void (*)(id, SEL, aldb::ColumnDef, id /*YYClassPropertyInfo*/))(void *) objc_msgSend)(
            (id) bindings->_cls, customColDef, *(bindings->_columnDef), propertyMeta->_info);
    }

    return bindings;
}

- (nullable YYClassPropertyInfo *)propertyInfo {
    return _propertyMeta ? _propertyMeta->_info : nil;
}

- (const std::shared_ptr<aldb::ColumnDef> &)columnDefine {
    return _columnDef;
}

- (nullable NSString *)columnName {
    return _columnName;
}

- (nullable NSString *)propertyName {
    return _propertyMeta ? _propertyMeta->_name : nil;
}

- (nullable Class)modelClass {
    return _cls;
}

- (ALDBColumnType)columnType {
    return _columnType;
}

- (nullable SEL)customPropertyValueSetter { // from ResultSet
    return _customSetter;
}

- (nullable SEL)customPropertyValueGetter { // to Column Value
    return _customGetter;
}

@end

static AL_FORCE_INLINE BOOL columnTypeForCType(YYEncodingType ctype, aldb::ColumnType &colType) {
    static const std::unordered_map<long, aldb::ColumnType> CTypesMap = {
        {YYEncodingTypeBool,    aldb::ColumnType::INT32_T},     ///< bool
        {YYEncodingTypeInt8,    aldb::ColumnType::INT32_T},     ///< char / BOOL
        {YYEncodingTypeUInt8,   aldb::ColumnType::INT32_T},     ///< unsigned char
        {YYEncodingTypeInt16,   aldb::ColumnType::INT32_T},     ///< short
        {YYEncodingTypeUInt16,  aldb::ColumnType::INT32_T},     ///< unsigned short
        {YYEncodingTypeInt32,   aldb::ColumnType::INT32_T},     ///< int
        {YYEncodingTypeUInt32,  aldb::ColumnType::INT32_T},     ///< unsigned int
                                                        //--------------------
        {YYEncodingTypeInt64,   aldb::ColumnType::INT64_T},    ///< long long
        {YYEncodingTypeUInt64,  aldb::ColumnType::INT64_T},    ///< unsigned long long
                                                        //--------------------
        {YYEncodingTypeFloat,       aldb::ColumnType::DOUBLE_T},  ///< float
        {YYEncodingTypeDouble,      aldb::ColumnType::DOUBLE_T},  ///< double
        {YYEncodingTypeLongDouble,  aldb::ColumnType::DOUBLE_T},  ///< long double
                                                            //--------------------
        {YYEncodingTypeCString, aldb::ColumnType::TEXT_T},    ///< char *
        {YYEncodingTypeSEL,     aldb::ColumnType::TEXT_T},
        {YYEncodingTypeClass,   aldb::ColumnType::TEXT_T},
    };
    
    auto iter = CTypesMap.find(ctype & YYEncodingTypeMask);
    if (iter != CTypesMap.end()) {
        colType = iter->second;
        return YES;
    }
    return NO;
}

static AL_FORCE_INLINE aldb::ColumnType columnTypeForProperty(_ALModelPropertyMeta *property) {
    if ((property->_type & YYEncodingTypeMask) == YYEncodingTypeObject) {
        static const std::unordered_map<long, aldb::ColumnType> NSTypesMap = {
            {YYEncodingTypeNSString,        aldb::ColumnType::TEXT_T},
            {YYEncodingTypeNSMutableString, aldb::ColumnType::TEXT_T},
            {YYEncodingTypeNSURL,           aldb::ColumnType::TEXT_T},
            {YYEncodingTypeNSNumber,        aldb::ColumnType::DOUBLE_T},
            {YYEncodingTypeNSDecimalNumber, aldb::ColumnType::DOUBLE_T},
            {YYEncodingTypeNSDate,          aldb::ColumnType::DOUBLE_T},
        };

        auto iter = NSTypesMap.find(property->_NSType);
        if (iter != NSTypesMap.end()) {
            return iter->second;
        }
    } else {
        aldb::ColumnType colType;
        if (columnTypeForCType(property->_type, colType)) {
            return colType;
        }
        
        const char *propertyEncoding = property->_info.typeEncoding.UTF8String;
        if (strcmp(propertyEncoding, @encode(std::string)) == 0 ||
            strcmp(propertyEncoding, @encode(const std::string)) == 0) {
            return aldb::ColumnType::TEXT_T;
        }
    }
    return aldb::ColumnType::BLOB_T;
}

