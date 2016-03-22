//
//  ALDBColumnInfo.m
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALDBColumnInfo.h"
#import "NSString+Helper.h"
#import "YYClassInfo.h"

@implementation ALDBColumnInfo

@synthesize dataType = _dataType;

- (void)setDataType:(NSString *)dataType {
    _dataType = isEmptyString(dataType) ? @"BLOB" : dataType.uppercaseString;
}

- (NSString *)dataType {
    return _dataType;
}

- (NSString *)columnDefine {
    return [self.name stringByAppendingFormat:@" %@%@",
            self.dataType,
            (isEmptyString(self.extra) ? @"" : [@" " stringByAppendingString:self.extra])];
}

- (NSString *)description {
    return [@[stringOrEmpty(self.property.name), stringOrEmpty(self.columnDefine)] componentsJoinedByString:@" => "];
}

@end
