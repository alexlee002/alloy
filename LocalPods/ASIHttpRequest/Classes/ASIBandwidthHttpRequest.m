//
//  ASIBandwidthHttpRequest.m
//  NetworkLayer
//
//  Created by chenzhibo on 15/6/16.
//  Copyright (c) 2015年 baidu. All rights reserved.
//

#import "ASIBandwidthHttpRequest.h"

static NSLock *bandwidthThrottlingLock = nil;
static const int ASIServerInternalErrorType = 500;		//定义server端内部错误

@interface ASIBandwidthHttpRequest ()
@property (nonatomic, retain) NSDate *throttleWakeUpTime;
@property (nonatomic, retain) NSDate *bandwidthMeasurementDate;
@property (nonatomic, assign) unsigned long bandwidthUsedInLastSecond;
@property (nonatomic, retain) NSMutableArray *bandwidthUsageTracker;
@property (nonatomic, assign) unsigned long averageBandwidthUsedPerSecond;
@end

@implementation ASIBandwidthHttpRequest
@synthesize maxBandwidthPerSecond=_maxBandwidthPerSecond;

+ (void)initialize
{
	if (self == [ASIBandwidthHttpRequest class]) {
		bandwidthThrottlingLock = [[NSLock alloc] init];
	}
}

- (void)dealloc {
	[_throttleWakeUpTime release];
	[_bandwidthMeasurementDate release];
	[_bandwidthUsageTracker removeAllObjects];
	[_bandwidthUsageTracker release];
	_bandwidthUsageTracker = nil;
	[super dealloc];
}

- (id)init {
	self = [super init];
	if (self) {
		NSMutableArray *tracherArray = [[NSMutableArray alloc] initWithCapacity:5];
		self.bandwidthUsageTracker = tracherArray;
		[tracherArray release];
	}
	
	return self;
}

#pragma mark bandwidth measurement / throttling

- (BOOL)hasThrottleWakeUpTime {
	return (nil == self.throttleWakeUpTime || [self.throttleWakeUpTime timeIntervalSinceDate:[NSDate date]] < 0);
}

- (long long)bandwidthReadBufferSize:(long long)bufferSize {
	// Reduce the buffer size if we're receiving data too quickly when bandwidth throttling is active
	// This just augments the throttling done in measureBandwidthUsage to reduce the amount we go over the limit
	
	if ([self isBandwidthThrottled]) {
		[bandwidthThrottlingLock lock];
		if (_maxBandwidthPerSecond > 0) {
			long long maxiumumSize  = (long long)_maxBandwidthPerSecond-(long long)_bandwidthUsedInLastSecond;
			if (maxiumumSize < 0) {
				// We aren't supposed to read any more data right now, but we'll read a single byte anyway so the CFNetwork's buffer isn't full
				bufferSize = 1;
			} else if (maxiumumSize/4 < bufferSize) {
				// We were going to fetch more data that we should be allowed, so we'll reduce the size of our read
				bufferSize = maxiumumSize/4;
			}
		}
		if (bufferSize < 1) {
			bufferSize = 1;
		}
		[bandwidthThrottlingLock unlock];
	}
	
	return bufferSize;
}

- (void)performThrottling
{
	if (![self readStream]) {
		return;
	}
	[self measureBandwidthUsage];
	if ([self isBandwidthThrottled]) {
		[bandwidthThrottlingLock lock];
		// Handle throttling
		if (nil != self.throttleWakeUpTime) {
			if ([self.throttleWakeUpTime timeIntervalSinceDate:[NSDate date]] > 0) {
				if ([self readStreamIsScheduled]) {
					[self unscheduleReadStream];
					#if DEBUG_THROTTLING
					NSLog(@"[THROTTLING] Sleeping request %@ until after %@",self,throttleWakeUpTime);
					#endif
				}
			} else {
				if (![self readStreamIsScheduled]) {
					[self scheduleReadStream];
					#if DEBUG_THROTTLING
					NSLog(@"[THROTTLING] Waking up request %@",self);
					#endif
				}
			}
		}
		[bandwidthThrottlingLock unlock];

	// Bandwidth throttling must have been turned off since we last looked, let's re-schedule the stream
	} else if (![self readStreamIsScheduled]) {
		[self scheduleReadStream];
	}
}

- (BOOL)isBandwidthThrottled
{
	[bandwidthThrottlingLock lock];
	BOOL throttle = (_maxBandwidthPerSecond > 0);
	[bandwidthThrottlingLock unlock];
	return throttle;
}

- (unsigned long)maxBandwidthPerSecond
{
	[bandwidthThrottlingLock lock];
	unsigned long amount = _maxBandwidthPerSecond;
	[bandwidthThrottlingLock unlock];
	return amount;
}

- (void)setMaxBandwidthPerSecond:(unsigned long)bytes
{
	[bandwidthThrottlingLock lock];
	_maxBandwidthPerSecond = bytes;
	[bandwidthThrottlingLock unlock];
}

- (void)incrementReadStreamBytes:(unsigned long)bytes {
	[bandwidthThrottlingLock lock];
	self.bandwidthUsedInLastSecond += bytes;
	[bandwidthThrottlingLock unlock];
}

- (void)recordBandwidthUsage
{
	if (self.bandwidthUsedInLastSecond == 0) {
		[self.bandwidthUsageTracker removeAllObjects];
	} else {
		NSTimeInterval interval = [self.bandwidthMeasurementDate timeIntervalSinceNow];
		while ((interval < 0 || [self.bandwidthUsageTracker count] > 5) && [self.bandwidthUsageTracker count] > 0) {
			[self.bandwidthUsageTracker removeObjectAtIndex:0];
			interval++;
		}
	}
	#if DEBUG_THROTTLING
	NSLog(@"[THROTTLING] ===Used: %u bytes of bandwidth in last measurement period===",bandwidthUsedInLastSecond);
	#endif
	[self.bandwidthUsageTracker addObject:@(self.bandwidthUsedInLastSecond)];
//	[self.bandwidthMeasurementDate release];
	NSDate *newDate = [[NSDate dateWithTimeIntervalSinceNow:1] retain];
	self.bandwidthMeasurementDate = newDate;
	[newDate release];
	self.bandwidthUsedInLastSecond = 0;

	NSUInteger measurements = [self.bandwidthUsageTracker count];
  if (measurements != 0) {
    unsigned long totalBytes = 0;
    for (NSNumber *bytes in self.bandwidthUsageTracker) {
      totalBytes += [bytes unsignedLongValue];
    }
    _averageBandwidthUsedPerSecond = totalBytes/measurements;
	  NSLog(@"averageBandwidth = %@",@(_averageBandwidthUsedPerSecond));
  }
}

- (unsigned long)averageBandwidthUsedPerSecond
{
	[bandwidthThrottlingLock lock];
	unsigned long amount = 	_averageBandwidthUsedPerSecond;
	[bandwidthThrottlingLock unlock];
	return amount;
}

- (void)measureBandwidthUsage
{
	// Other requests may have to wait for this lock if we're sleeping, but this is fine, since in that case we already know they shouldn't be sending or receiving data
	[bandwidthThrottlingLock lock];

	if (!self.bandwidthMeasurementDate || [self.bandwidthMeasurementDate timeIntervalSinceNow] < -0) {
		[self recordBandwidthUsage];
	}

	// Are we performing bandwidth throttling?
	if (_maxBandwidthPerSecond > 0) {
		// How much data can we still send or receive this second?
		long long bytesRemaining = (long long)_maxBandwidthPerSecond - (long long)_bandwidthUsedInLastSecond;

		// Have we used up our allowance?
		if (bytesRemaining < 0) {

			// Yes, put this request to sleep until a second is up, with extra added punishment sleeping time for being very naughty (we have used more bandwidth than we were allowed)
			double extraSleepyTime = (-bytesRemaining/(_maxBandwidthPerSecond*1.0));
			//[self.throttleWakeUpTime release];
			NSDate *newDate = [[NSDate alloc] initWithTimeInterval:extraSleepyTime sinceDate:self.bandwidthMeasurementDate];
			self.throttleWakeUpTime = newDate;
			[newDate release];
		}
	}
	[bandwidthThrottlingLock unlock];
}

#pragma mark -- 重写readResponseHeaders
//重写原因:增加对响应头部的status错误码处理逻辑,如果是大于等于500，则不继续写入文件缓存
- (void)readResponseHeaders {
	[super readResponseHeaders];
	
	if ([self responseHeaders]) {
		//判断响应头部的status状态
		NSInteger status = self.responseStatusCode;
		if (status >= 500) {
			NSError *statusError = [[NSError alloc] initWithDomain:NetworkRequestErrorDomain code:ASIServerInternalErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"server internal error",NSLocalizedDescriptionKey,nil]];
			[self failWithError:statusError];
			[statusError release];
		}
	}
}


@end
