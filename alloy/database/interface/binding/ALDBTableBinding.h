//
//  ALDBTableBinding.h
//  alloy
//
//  Created by Alex Lee on 08/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBColumnBinding.h"
#import "ALDBIndexBinding.h"

NS_ASSUME_NONNULL_BEGIN
@interface ALDBTableBinding : NSObject

- (Class)bindingClass;

- (NSString *)columnNameForProperty:(NSString *)propertyName;

- (NSArray<ALDBColumnBinding *> *)columnBindings;
- (ALDBColumnBinding *)bindingForColumn:(NSString *)colName;

- (ALDBIndexBinding *)indexBindingWithProperties:(NSArray<NSString *> *)indexPropertyNames unique:(BOOL)unique;

- (NSArray<NSString */*propertyName*/> *)allPrimaryKeys;
- (NSArray<NSArray<NSString */*propertyName*/> *> *)allUniqueKeys;
- (NSArray<NSArray<NSString */*propertyName*/> *> *)allIndexKeys;

@end
NS_ASSUME_NONNULL_END




