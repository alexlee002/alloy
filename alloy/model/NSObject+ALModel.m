//
//  NSObject+ALModel.m
//  patchwork
//
//  Created by Alex Lee on 27/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+ALModel.h"
#import "_ALModelMeta.h"
#import "_ALModelHelper.h"
#import "ALMacros.h"
#import <objc/message.h>

static AL_FORCE_INLINE BOOL _YYIsStructAvailableForKeyArchiver(NSString *structTypeEncoding) {
    static NSSet *availableTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableTypes = [NSSet setWithObjects:
                          // 32 bit
                          @"{CGSize=ff}", @"{CGPoint=ff}", @"{CGRect={CGPoint=ff}{CGSize=ff}}",
                          @"{CGAffineTransform=ffffff}", @"{UIEdgeInsets=ffff}", @"{UIOffset=ff}",
                          // 64 bit
                          @"{CGSize=dd}", @"{CGPoint=dd}", @"{CGRect={CGPoint=dd}{CGSize=dd}}",
                          @"{CGAffineTransform=dddddd}", @"{UIEdgeInsets=dddd}", @"{UIOffset=dd}", nil];
    });
    return [availableTypes containsObject:structTypeEncoding];
}

/// Add indent to string (exclude first line)
static AL_FORCE_INLINE  NSMutableString *ModelDescriptionAddIndent(NSMutableString *desc, NSUInteger indent) {
    for (NSUInteger i = 0, max = desc.length; i < max; i++) {
        unichar c = [desc characterAtIndex:i];
        if (c == '\n') {
            for (NSUInteger j = 0; j < indent; j++) {
                [desc insertString:@"    " atIndex:i + 1];
            }
            i += indent * 4;
            max += indent * 4;
        }
    }
    return desc;
}

/// Generaate a description string
static AL_FORCE_INLINE  NSString *ModelDescription(NSObject *model) {
    static const int kDescMaxLength = 100;
    
    if (!model) {
        return @"<nil>";
    }
    if (model == (id) kCFNull) {
        return @"<null>";
    }
    if (![model isKindOfClass:[NSObject class]]) {
        return [NSString stringWithFormat:@"%@", model];
    }
    
    _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:model.class];
    switch (modelMeta->_NSType) {
        case YYEncodingTypeNSString:
        case YYEncodingTypeNSMutableString: {
            return [NSString stringWithFormat:@"\"%@\"", model];
        }
            
        case YYEncodingTypeNSValue:
        case YYEncodingTypeNSData:
        case YYEncodingTypeNSMutableData: {
            NSString *tmp = model.description;
            if (tmp.length > kDescMaxLength) {
                tmp = [tmp substringToIndex:kDescMaxLength];
                tmp = [tmp stringByAppendingString:@"..."];
            }
            return tmp;
        }
            
        case YYEncodingTypeNSNumber:
        case YYEncodingTypeNSDecimalNumber:
        case YYEncodingTypeNSDate:
        case YYEncodingTypeNSURL: {
            return [NSString stringWithFormat:@"%@", model];
        }
            
        case YYEncodingTypeNSSet:
        case YYEncodingTypeNSMutableSet: {
            model = ((NSSet *) model).allObjects;
        }  // no break
            
        case YYEncodingTypeNSArray:
        case YYEncodingTypeNSMutableArray: {
            NSArray *array        = (id) model;
            NSMutableString *desc = [NSMutableString string];
            if (array.count == 0) {
                return [desc stringByAppendingString:@"[]"];
            } else {
                [desc appendFormat:@"[\n"];
                for (NSUInteger i = 0, max = array.count; i < max; i++) {
                    NSObject *obj = array[i];
                    [desc appendString:@"    "];
                    [desc appendString:ModelDescriptionAddIndent(ModelDescription(obj).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
                }
                [desc appendString:@"]"];
                return desc;
            }
        }
        case YYEncodingTypeNSDictionary:
        case YYEncodingTypeNSMutableDictionary: {
            NSDictionary *dic     = (id) model;
            NSMutableString *desc = [NSMutableString string];
            if (dic.count == 0) {
                return [desc stringByAppendingString:@"{}"];
            } else {
                NSArray *keys = dic.allKeys;
                
                [desc appendFormat:@"{\n"];
                for (NSUInteger i = 0, max = keys.count; i < max; i++) {
                    NSString *key   = keys[i];
                    NSObject *value = dic[key];
                    [desc appendString:@"    "];
                    [desc appendFormat:@"%@ = %@", key,
                                       ModelDescriptionAddIndent(ModelDescription(value).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
                }
                [desc appendString:@"}"];
            }
            return desc;
        }
            
        default: {
            NSMutableString *desc = [NSMutableString string];
            [desc appendFormat:@"<%@: %p>", model.class, model];
            if (modelMeta->_allPropertyMetasDict.count == 0) {
                return desc;
            }
            
            // sort property names
            NSArray *properties = [modelMeta->_allPropertyMetasDict.allValues
                sortedArrayUsingComparator:^NSComparisonResult(_ALModelPropertyMeta *p1, _ALModelPropertyMeta *p2) {
                    return [p1->_name compare:p2->_name];
                }];
            
            [desc appendFormat:@" {\n"];
            for (NSUInteger i = 0, max = properties.count; i < max; i++) {
                _ALModelPropertyMeta *property = properties[i];
                NSString *propertyDesc;
                if (property->_isCNumber) {
                    NSNumber *num = _ALModelCreateNumberFromProperty(model, property);
                    propertyDesc  = num.stringValue;
                } else {
                    switch (property->_type & YYEncodingTypeMask) {
                        case YYEncodingTypeObject: {
                            id v = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, property->_getter);
                            propertyDesc = ModelDescription(v);
                            if (!propertyDesc) {
                                propertyDesc = @"<nil>";
                            }
                        } break;
                        case YYEncodingTypeClass: {
                            id v = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, property->_getter);
                            propertyDesc = ((NSObject *) v).description;
                            if (!propertyDesc) {
                                propertyDesc = @"<nil>";
                            }
                        } break;
                        case YYEncodingTypeSEL: {
                            SEL sel = ((SEL(*)(id, SEL))(void *) objc_msgSend)((id) model, property->_getter);
                            if (sel) {
                                propertyDesc = NSStringFromSelector(sel);
                            } else {
                                propertyDesc = @"<NULL>";
                            }
                        } break;
                        case YYEncodingTypeBlock: {
                            id block = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, property->_getter);
                            propertyDesc = block ? ((NSObject *) block).description : @"<nil>";
                        } break;
                        case YYEncodingTypeCArray:
                        case YYEncodingTypeCString:
                        case YYEncodingTypePointer: {
                            void *pointer = ((void *(*) (id, SEL))(void *) objc_msgSend)((id) model, property->_getter);
                            propertyDesc  = [NSString stringWithFormat:@"%p", pointer];
                        } break;
                        case YYEncodingTypeStruct:
                        case YYEncodingTypeUnion: {
                            NSValue *value = [model valueForKey:property->_name];
                            propertyDesc   = value ? value.description : @"{unknown}";
                        } break;
                        default:
                            propertyDesc = @"<unknown>";
                    }
                }
                
                propertyDesc = ModelDescriptionAddIndent(propertyDesc.mutableCopy, 1);
                [desc appendFormat:@"    %@ = %@", property->_name, propertyDesc];
                [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
            }
            [desc appendFormat:@"}"];
            return desc;
        }
    }
}

@implementation NSObject (ALModel)

- (nullable instancetype)al_modelCopy {
    if (self == (id) kCFNull) {
        return self;
    }
    
    _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:self.class];
    if (modelMeta->_NSType) {
        return [self copy];
    }
    
    NSObject *one = [[self.class alloc] init];
    for (_ALModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetasDict.allValues) {
        if (!propertyMeta->_getter) {
            continue;
        }
        if (!propertyMeta->_setter) {
            NSValue *value = [self valueForKey:propertyMeta->_name];
            _ALModelKVCSetValueForProperty(one, value, propertyMeta);
            continue;
        }
        
        if (propertyMeta->_isCNumber) {
            switch (propertyMeta->_type & YYEncodingTypeMask) {
                case YYEncodingTypeBool: {
                    bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeInt64:
                case YYEncodingTypeUInt64: {
                    uint64_t num = ((uint64_t(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeDouble: {
                    double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, double))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeInt32:
                case YYEncodingTypeUInt32: {
                    uint32_t num = ((uint32_t(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeFloat: {
                    float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeInt8:
                case YYEncodingTypeUInt8: {
                    uint8_t num = ((uint8_t(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeInt16:
                case YYEncodingTypeUInt16: {
                    uint16_t num = ((uint16_t(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                } break;
                case YYEncodingTypeLongDouble: {
                    long double num =
                        ((long double (*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id) one, propertyMeta->_setter, num);
                }  // break; commented for code coverage in next line
                default:
                    break;
            }
        } else {
            switch (propertyMeta->_type & YYEncodingTypeMask) {
                case YYEncodingTypeObject:
                case YYEncodingTypeClass:
                case YYEncodingTypeBlock: {
                    id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) one, propertyMeta->_setter, value);
                } break;
                case YYEncodingTypeSEL:
                case YYEncodingTypePointer:
                case YYEncodingTypeCString: {
                    size_t value = ((size_t(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    ((void (*)(id, SEL, size_t))(void *) objc_msgSend)((id) one, propertyMeta->_setter, value);
                } break;
                case YYEncodingTypeStruct:
                case YYEncodingTypeUnion: {
                    @try {
                        NSValue *value = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
                        if (value) {
                            [one setValue:value forKey:propertyMeta->_name];
                        }
                    } @catch (NSException *exception) {
                    }
                }  // break; commented for code coverage in next line
                default:
                    break;
            }
        }
    }
    return one;
}

- (void)al_modelEncodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) {
        return;
    }
    
    if (self == (id) kCFNull) {
        [((id<NSCoding>) self) encodeWithCoder:aCoder];
        return;
    }
    
    _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:self.class];
    if (modelMeta->_NSType) {
        [((id<NSCoding>) self) encodeWithCoder:aCoder];
        return;
    }
    
    for (_ALModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetasDict.allValues) {
        if (!propertyMeta->_getter) {
            continue;
        }
        
        if (propertyMeta->_isCNumber) {
            NSNumber *value = _ALModelCreateNumberFromProperty(self, propertyMeta);
            if (value) {
                [aCoder encodeObject:value forKey:propertyMeta->_name];
            }
        } else {
            switch (propertyMeta->_type & YYEncodingTypeMask) {
                case YYEncodingTypeObject: {
                    id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    if (value && (propertyMeta->_NSType || [value respondsToSelector:@selector(encodeWithCoder:)])) {
                        if ([value isKindOfClass:[NSValue class]]) {
                            @try {
                                [aCoder encodeObject:value forKey:propertyMeta->_name];
                            } @catch (NSException *e) {
                            }
                        } else {
                            [aCoder encodeObject:value forKey:propertyMeta->_name];
                        }
                    }
                } break;
                case YYEncodingTypeSEL: {
                    SEL value = ((SEL(*)(id, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_getter);
                    if (value) {
                        NSString *str = NSStringFromSelector(value);
                        [aCoder encodeObject:str forKey:propertyMeta->_name];
                    }
                } break;
                case YYEncodingTypeStruct:
                case YYEncodingTypeUnion: {
                    if (propertyMeta->_isKVCCompatible &&
                        _YYIsStructAvailableForKeyArchiver(propertyMeta->_info.typeEncoding)) {
                        @try {
                            NSValue *value = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
                            [aCoder encodeObject:value forKey:propertyMeta->_name];
                        } @catch (NSException *exception) {
                        }
                    }
                } break;
                    
                default:
                    break;
            }
        }
    }
}

- (nullable id)al_modelInitWithCoder:(NSCoder *)aDecoder {
    if (!aDecoder) {
        return self;
    }
    if (self == (id) kCFNull) {
        return self;
    }
    
    _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:self.class];
    if (modelMeta->_NSType) {
        return self;
    }
    
    for (_ALModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetasDict.allValues) {
        if (!propertyMeta->_setter) {
            NSValue *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
            _ALModelKVCSetValueForProperty(self, value, propertyMeta);
            continue;
        }
        
        if (propertyMeta->_isCNumber) {
            NSNumber *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
            if ([value isKindOfClass:[NSNumber class]]) {
                _ALModelSetNumberToProperty(self, value, propertyMeta);
                [value class];
            }
        } else {
            YYEncodingType type = propertyMeta->_type & YYEncodingTypeMask;
            switch (type) {
                case YYEncodingTypeObject: {
                    id value = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) self, propertyMeta->_setter, value);
                } break;
                case YYEncodingTypeSEL: {
                    NSString *str = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    if ([str isKindOfClass:[NSString class]]) {
                        SEL sel = NSSelectorFromString(str);
                        ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id) self, propertyMeta->_setter, sel);
                    }
                } break;
                case YYEncodingTypeStruct:
                case YYEncodingTypeUnion: {
                    NSValue *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    _ALModelKVCSetValueForProperty(self, value, propertyMeta);
                } break;
                    
                default:
                    break;
            }
        }
    }
    return self;
}

- (NSUInteger)al_modelHash {
    if (self == (id) kCFNull) {
        return [self hash];
    }
    
    _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:self.class];
    if (modelMeta->_NSType) {
        return [self hash];
    }
    
    NSUInteger value = 0;
    NSUInteger count = 0;
    for (_ALModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetasDict.allValues) {
        if (!propertyMeta->_isKVCCompatible) {
            continue;
        }
        @try {
            value ^= [[self valueForKey:NSStringFromSelector(propertyMeta->_getter)] hash];
            count++;
        } @catch (NSException *e) {}
    }
    if (count == 0) {
        value = (long) ((__bridge void *) self);
    }
    return value;
}

- (BOOL)al_modelIsEquel:(id)model {
    if (self == model) {
        return YES;
    }
    if (![model isMemberOfClass:self.class]) {
        return NO;
    }
    
    _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:self.class];
    if (modelMeta->_NSType) {
        return [self isEqual:model];
    }
    if ([self hash] != [model hash]) {
        return NO;
    }
    
    for (_ALModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetasDict.allValues) {
        if (!propertyMeta->_isKVCCompatible) {
            continue;
        }
        
        id this = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
        id that = [model valueForKey:NSStringFromSelector(propertyMeta->_getter)];
        if (this == that) {
            continue;
        }
        if (this == nil || that == nil) {
            return NO;
        }
        if (![this isEqual:that]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)al_modelDescription {
    return ModelDescription(self);
}
@end
