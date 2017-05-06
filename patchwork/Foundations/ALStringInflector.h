//
//  ALStringInflector.h
//  patchwork
//
//  Created by Alex Lee on 27/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>


//@see  https://github.com/mattt/InflectorKit/blob/master/InflectorKit/TTTStringInflector.m
@interface ALStringInflector : NSObject

+ (instancetype)defaultInflector;
- (instancetype)init;

- (NSString *)singularize:(NSString *)string;
- (NSString *)pluralize:(NSString *)string;
@end


@interface NSString (ALStringInflector)

- (NSString *)al_singularize;
- (NSString *)al_pluralize;

@end
