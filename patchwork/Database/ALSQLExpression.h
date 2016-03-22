//
//  ALSQLExpression.h
//  patchwork
//
//  Created by Alex Lee on 3/21/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALSQLExpression : NSObject
@property(readonly) NSString *stringify;

+ (nullable instancetype)expressionWithValue:(id)value;

@end


@interface NSString (ALSQLExpression)

- (ALSQLExpression *)SQLExpression;

@end

@interface NSNumber (ALSQLExpression)

- (ALSQLExpression *)SQLExpression;

@end

NS_ASSUME_NONNULL_END
