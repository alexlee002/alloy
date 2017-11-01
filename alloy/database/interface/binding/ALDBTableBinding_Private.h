//
//  ALDBTableBinding_Private.h
//  alloy
//
//  Created by Alex Lee on 08/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBTableBinding.h"
#import "_ALModelMeta.h"

@interface ALDBTableBinding () {
    _ALModelMeta *_modelMeta;
}
+ (instancetype)bindingsWithClass:(Class)cls;
@end
