//
//  ASIBandwidthHttpRequest.h
//  NetworkLayer
//
//  Created by chenzhibo on 15/6/16.
//  Copyright (c) 2015年 baidu. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface ASIBandwidthHttpRequest : ASIHTTPRequest

/*
 *最大限速值
 */
@property (nonatomic, assign) unsigned long maxBandwidthPerSecond;

#pragma mark bandwidth measurement / throttling
/*
 *每秒的平均速度
 */
- (unsigned long)averageBandwidthUsedPerSecond;

/*
 *执行限速功能,如果满足限速条件，则开启限速，否则关闭
 */
- (void)performThrottling;

@end
