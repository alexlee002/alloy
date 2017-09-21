//
//  ALDatabase.h
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

#if DEBUG
#define ALDB_LOG_ERROR(catchable)                                       \
    {                                                                   \
        auto obj = (catchable);                                         \
        if (obj && obj->has_error()) {                                  \
            ALLogError(@"%s", obj->get_error()->description().c_str()); \
        }                                                               \
    }
#else
#define ALDB_LOG_ERROR(catchable) \
    do {} while (0)
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ALDatabase : NSObject

@property(nonatomic, readonly, copy) NSString *path;

+ (nullable instancetype)databaseWithPath:(NSString *)path;
+ (nullable instancetype)databaseWithPath:(NSString *)path keepAlive:(BOOL)keepAlive;

- (void)keepAlive:(BOOL)yesOrNo;
- (void)close;

@end
NS_ASSUME_NONNULL_END
