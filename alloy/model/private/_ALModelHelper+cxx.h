//
//  _ALModelHelper+cxx.h
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBExpr.h"

NS_ASSUME_NONNULL_BEGIN
@class ALDBColumnBinding;
OBJC_EXPORT id _Nullable _ALColumnValueForModelProperty(id model, ALDBColumnBinding *binding);

OBJC_EXPORT BOOL _ALIsAutoIncrementColumn(ALDBColumnBinding *binding);

extern std::shared_ptr<const ALDBCondition> _ALDefaultModelUpdateCondition(NSObject *_Nonnull model);

NS_ASSUME_NONNULL_END
