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

@synthesize type = _type;

- (void)setType:(NSString *)dataType {
    _type = isEmptyString(dataType) ? @"BLOB" : dataType.uppercaseString;
}


- (NSString *)columnDefine {
    return [self.name stringByAppendingFormat:@" %@%@",
            self.type,
            (isEmptyString(self.constraint) ? @"" : [@" " stringByAppendingString:self.constraint])];
}

- (NSString *)description {
    return [@[stringOrEmpty(self.property.name), stringOrEmpty(self.columnDefine)] componentsJoinedByString:@" => "];
}

@end
