//
//  Singleton_Template.h
//  patchwork
//
//  Created by Alex Lee on 3/11/15.
//  Copyright © 2015 Alex Lee. All rights reserved.
//


#undef  AS_SINGLETON
#define AS_SINGLETON                    \
        + (instancetype)sharedInstance; \
        + (void)destroy;

#if __has_feature(objc_arc)
#   undef  SYNTHESIZE_SINGLETON
#   define SYNTHESIZE_SINGLETON                         \
            static id __singleton_instance__ = nil;     \
            + (instancetype)sharedInstance {            \
                @synchronized(self) {                   \
                    if (__singleton_instance__) {       \
                        return __singleton_instance__;  \
                    }                                   \
                }                                       \
                return [[self alloc] init];             \
            }                                           \
                                                        \
            + (instancetype)allocWithZone:(struct _NSZone *)zone {        \
                static dispatch_once_t onceToken;       \
                dispatch_once( &onceToken, ^{ __singleton_instance__ = [super allocWithZone:zone]; } ); \
                return __singleton_instance__;          \
            }                                           \
                                                        \
            + (instancetype)alloc {                     \
                return [self allocWithZone:NULL];       \
            }                                           \
                                                        \
            + (instancetype)new {                       \
                return [self allocWithZone:NULL];       \
            }                                           \
                                                        \
            - (id)copy { return self; }                 \
            - (id)mutableCopy { return self; }          \
                                                        \
            + (void)destroy {                           \
                __singleton_instance__ = nil;           \
            }
#else
#   undef  SYNTHESIZE_SINGLETON
#   define SYNTHESIZE_SINGLETON                         \
            static id __singleton_instance__ = nil;     \
            + (instancetype)sharedInstance {            \
                return [[self alloc] init];              \
            }                                           \
                                                        \
            + (instancetype)allocWithZone:(struct _NSZone *)zone { \
                static dispatch_once_t onceToken;       \
                dispatch_once( &onceToken, ^{ __singleton_instance__ = [super allocWithZone:zone]; } ); \
                return __singleton_instance__;          \
            }                                           \
                                                        \
            + (instancetype)alloc {                     \
                return [self allocWithZone:NULL];       \
            }                                           \
                                                        \
            + (instancetype)new {                       \
                return [self allocWithZone:NULL];       \
            }                                           \
                                                        \
            - (id)copy { return self; }                 \
            - (id)mutableCopy { return self; }          \
                                                        \
            + (id)copyWithZone:(struct _NSZone *) { return self; }          \
            + (id)mutableCopyWithZone:(struct _NSZone *) {  return self; }  \
                                                        \
            - (instancetype)retain {  return self; }    \
            - (oneway void)release {}                   \
            - (instancetype)autorelease { return self; }\
            - (NSUInteger)retainCount { return NSUIntegerMax; } \
                                                        \
            + (void)destroy {                           \
                [__singleton_instance__ dealloc];       \
                __singleton_instance__ = nil;           \
            }                                           \

#endif
