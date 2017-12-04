//
//  ALModelORMBase.h
//  alloy
//
//  Created by Alex Lee on 01/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBHandle.h"

NS_ASSUME_NONNULL_BEGIN
@interface ALModelORMBase : NSObject

- (nullable ALDBStatement *)preparedStatement;

@end

NS_ASSUME_NONNULL_END
