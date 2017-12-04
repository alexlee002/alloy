//
//  ALModelORMBase+Private.h
//  alloy
//
//  Created by Alex Lee on 01/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelORMBase.h"

@interface ALModelORMBase () {
  @protected
    Class        _modelClass;
    ALDBHandle  *_database;
    
//    ALDBCondition _whereClause;
//    std::list<const aldb::OrderClause> _orderByList;
//    ALDBExpr _limitClause;
//    ALDBExpr _offsetClause;
//    BOOL _reset;
}

@end
