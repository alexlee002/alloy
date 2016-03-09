//
//  ALHTTPReuestAdaptorProtocol.h
//  patchwork
//
//  Created by Alex Lee on 3/9/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALHTTPRequest;
@protocol ALHTTPReuestAdaptorProtocol <NSObject>
- (id)objectTransformFromALRequest:(__kindof ALHTTPRequest *)request;
- (NSDictionary<NSNumber *, id> *)allRequestObjects;
@end
