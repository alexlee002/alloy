//
//  __ALResultSetEnumerator.m
//  alloy
//
//  Created by Alex Lee on 23/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALResultSetEnumerator.h"
#import "ALUtilitiesHeader.h"
#import "__ALModelMeta+ActiveRecord.h"
#import "__ALPropertyColumnBindings+private.h"
#import <objc/message.h>
#import "NSString+ALHelper.h"
#import "__ALModelHelper.h"

@implementation __ALResultSetEnumerator {
    ALDBResultSet *_rs;
    Class _cls;
    std::list<const ALDBResultColumn> _columns;
    
    NSArray<ALPropertyColumnBindings *> *_bindings; // maybe contains NSNull.null
}

+ (NSEnumerator *)enumatorWithResultSet:(ALDBResultSet *)rs
                             modelClass:(Class)cls
                          resultColumns:(const std::list<const ALDBResultColumn>)columns {
    
    __ALResultSetEnumerator *enumator = [[self alloc] init];
    enumator->_rs = rs;
    enumator->_cls = cls;
    enumator->_columns.insert(enumator->_columns.end(), columns.begin(), columns.end());
    return enumator;
}

- (id)nextObject {
    al_guard_or_return(_rs != nil, nil);
    
    if (_cls == nil) {
        return nil;
    }
    
    if (![_rs next]) {
        return nil;
    }
    
    id obj = [[_cls alloc] init];
    int index = 0;
    for (ALPropertyColumnBindings *binding in [self columnBindings]) {
        if (al_unwrapNil(binding)) {
            [self setPropertyForModel:obj atColumnIndex:index withBinding:binding];
        }
        index ++;
    }
    return obj;
}

- (void)setPropertyForModel:(id)obj atColumnIndex:(int)index withBinding:(ALPropertyColumnBindings *)binding {
    if (![binding isKindOfClass:ALPropertyColumnBindings.class]) {
        return;
    }
    SEL customSetter = [binding customPropertyValueFromColumnTransformer];
    if (customSetter != nil) {
        ((void (*)(id, SEL, id /*ALDBResultSet*/, int /*index*/))(void *) objc_msgSend)((id) obj, customSetter,
                                                                                        (id) _rs, index);
    } else {
        _ModelSetValueForProperty(obj, _rs[index], binding->_propertyMeta, nil, nil);
    }
}

- (NSArray<ALPropertyColumnBindings *> *)columnBindings {
    if (_bindings == nil) {
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_columns.size()];
        
        _ALModelTableBindings *modelBindings = nil;
        auto it = _columns.begin();
        for (int idx = 0; idx < _rs.columnCount; ++idx) {
            ALPropertyColumnBindings *binding = nil;
            NSString *columnName = [_rs columnNameAt:idx];
            if (it != _columns.end()) {
                binding = (*it).column_binding();
                if (binding && ![[binding columnName] isEqualToString:columnName]) {
                    ALAssert(NO, @"column name is not match! WTF?");
                    binding = nil;
                }
                ++ it;
            }
            if (binding == nil) {
                if (modelBindings == nil) {
                    modelBindings = [_ALModelTableBindings bindingsWithClass:_cls];
                }
                binding = modelBindings->_columnsDict[columnName];
            }
            ALAssert(binding != nil, @"column binding is nil! column:%@", columnName);
            [arr addObject:al_wrapNil(binding)];
        }
        _bindings = [arr copy];
    }
    return _bindings;
}

@end
