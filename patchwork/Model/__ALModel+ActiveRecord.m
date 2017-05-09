//
//  ALModel+ActiveRecord_private.m
//  patchwork
//
//  Created by Alex Lee on 21/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "__ALModel+ActiveRecord.h"
#import "ALModel+ActiveRecord.h"
#import "NSString+ALHelper.h"
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN


@implementation ALModel (ActiveRecord_private)

#pragma mark - belongs to
//- (nullable __kindof ALModel *)al_belongsTo:(NSString *)modelClassName
//                          relatedProperties:(NSArray<NSString *> *)propertyNames {
//    Class modelClass = NSClassFromString(modelClassName);
//    if (modelClass == Nil) {
//        return nil;
//    }
//    
//    validatePropertyColumnMappings(self.class, propertyNames, nil);
//    for (NSString *name in propertyNames) {
//        
//    }
//    
//    NSString *selectorName = [[modelClassName stringByLowercaseFirst] stringByAppendingString:@"Id"];
//    SEL selector = NSSelectorFromString(selectorName);
//    if (![self respondsToSelector:selector]) {
//        return nil;
//    }
//    NSInteger recId = ((NSInteger(*)(id, SEL))(void *) objc_msgSend)((id) self, selector);
//    return [modelClass modelWithId:recId];
//}
//
//- (void)al_setModel:(__kindof ALModel *)model belongsTo:(NSString *)relatedClassName {
//    NSString *propertyName = [[relatedClassName stringByLowercaseFirst] stringByAppendingString:@"Id"];
//    validatePropertyColumnMapping(self.class, propertyName, (void)nil);
// 
//    [self setValue:@(model.rowid) forKey:propertyName];
//    // save to database outside?
//    //[self updateProperties:@[propertyName] repleace:NO];
//}
//
//#pragma mark - has many
//- (void)al_addModel:(__kindof ALModel *)model {
//    validateModelRecordBinding(self, (void)nil);
//    
//    NSString *relIdPropertyName = [[NSStringFromClass(self.class) stringByLowercaseFirst] stringByAppendingString:@"Id"];
//    validatePropertyColumnMapping(model.class, relIdPropertyName, (void)nil);
//    [model setValue:@(self.rowid) forKey:relIdPropertyName];
//    [model updateProperties:@[relIdPropertyName] repleace:NO];
//}
//
//- (void)al_removeModel:(__kindof ALModel *)model {
//    NSString *relIdPropertyName = [[NSStringFromClass(self.class) stringByLowercaseFirst] stringByAppendingString:@"Id"];
//    validatePropertyColumnMapping(model.class, relIdPropertyName, (void)nil);
//    [model setValue:nil forKey:relIdPropertyName];
//    [model updateProperties:@[relIdPropertyName] repleace:NO];
//}

@end

NS_ASSUME_NONNULL_END
