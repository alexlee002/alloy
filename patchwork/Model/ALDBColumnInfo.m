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
    _type = al_isEmptyString(dataType) ? @"BLOB" : dataType.uppercaseString;
}


- (NSString *)columnDefine {
    return [self.name stringByAppendingFormat:@" %@%@",
            self.type,
            (al_isEmptyString(self.constraint) ? @"" : [@" " stringByAppendingString:self.constraint])];
}

- (NSString *)description {
    return [@[al_stringOrEmpty(self.property.name), al_stringOrEmpty(self.columnDefine)] componentsJoinedByString:@" => "];
}

@end
