//
//  ALSQLDropTable.h
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"

@interface ALSQLDropTable : ALSQLStatement

- (instancetype)dropTable:(NSString *)tableName;

@end
