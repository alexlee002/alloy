//
//  ALModelSelect+Private.h
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelSelect.h"
#import "sql_select.hpp"

@interface ALModelSelect () {
  @package
    aldb::SQLSelect _statement;
    Class _modelClass;
    std::shared_ptr<ALDBResultColumnList> _resultColumns;
}

@end
