//
//  ALURLRequestManager.m
//  patchwork
//
//  Created by Alex Lee on 3/4/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALURLRequestManager.h"

#if AL_ENABLE_ASIHTTPREQUEST
#   import "ASIHTTPRequest.h"
#endif

#if AL_ENABLE_NSURLSESSION
#endif


@implementation ALURLRequestManager {
    __weak id<ALURLRequestManagerDelegate>     _delegate;
    NSMutableDictionary<NSString *, id<ALHTTPReuestAdaptorProtocol> > *_requestAdaptors;
    
#if AL_ENABLE_NSURLSESSION
    NSURLSession *_session;
#endif
}


+ (instancetype)managerWithDelegate:(id<ALURLRequestManagerDelegate>)delegate {
    ALURLRequestManager *manager = [[self alloc] init];
    manager->_delegate = delegate;
    manager->_requestAdaptors = [NSMutableDictionary dictionary];
    return manager;
}

- (void)fetchRequestsWithCompletion:(NSArray<ALHTTPRequest *> *)completion {
    
}

- (void)sendRequest:(ALHTTPRequest *)request {
    Class cls = [_delegate adaptorClassForRequest:request];
    if (![cls conformsToProtocol:@protocol(ALHTTPReuestAdaptorProtocol)]) {
        NSAssert(NO, @"adaptor class should confirms to protocol 'ALHTTPReuestAdaptorProtocol'");
        return;
    }
    NSString *adaptorName = NSStringFromClass(cls);
    id<ALHTTPReuestAdaptorProtocol> adaptor = _requestAdaptors[adaptorName];
    if (adaptor == nil) {
        adaptor = [[cls alloc] init];
        _requestAdaptors[adaptorName] = adaptor;
    }
#if AL_ENABLE_ASIHTTPREQUEST
    ASIHTTPRequest *asiRequest = [adaptor objectTransformFromALRequest:request];
    [asiRequest startAsynchronous];
#endif
    
#if AL_ENABLE_NSURLSESSION
#endif
}

- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier {

}

@end
