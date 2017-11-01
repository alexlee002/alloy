//
//  ALDatabase+Core.h
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"

NS_ASSUME_NONNULL_BEGIN
@interface ALDatabase (Core)

- (BOOL)inTransaction:(void (^)(BOOL *rollback))transaction error:(NSError *_Nullable*)error;

@end
NS_ASSUME_NONNULL_END
