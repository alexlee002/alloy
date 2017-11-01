//
//  ALDBCodingMacros_Private.h
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef ALDBCodingMacros_Private_h
#define ALDBCodingMacros_Private_h

#import "ALDBColumnBinding.h"

#undef __ALDB_PROPERTY_BASE_DEF
#define __ALDB_PROPERTY_BASE_DEF                            \
  public:                                                   \
    ALDBColumnBinding *columnBinding() const;               \
    const Class bindingClass() const;                       \
                                                            \
  protected:                                                \
    void setBinding(Class cls, ALDBColumnBinding *binding); \
    Class _cls;                                             \
    ALDBColumnBinding *_columnBinding;

#undef __ALDB_PROPERTY_BASE_CTOR
#define __ALDB_PROPERTY_BASE_CTOR(cls, binding) _cls(cls), _columnBinding(binding)

#undef __ALDB_PROPERTY_BASE_CTOR1
#define __ALDB_PROPERTY_BASE_CTOR1(other) _cls(other.bindingClass()), _columnBinding(other.columnBinding())

#undef __ALDB_CAST_PROPERTY
#define __ALDB_CAST_PROPERTY(obj)    (obj).bindingClass(), (obj).columnBinding()

#undef __ALDB_PROPERTY_BASE_IMP
#define __ALDB_PROPERTY_BASE_IMP(CLASS)                             \
    ALDBColumnBinding *CLASS::columnBinding() const {               \
        return _columnBinding;                                      \
    }                                                               \
                                                                    \
    const Class CLASS::bindingClass() const {                       \
        return _cls;                                                \
    }                                                               \
                                                                    \
    void CLASS::setBinding(Class cls, ALDBColumnBinding *binding) { \
        _cls           = cls;                                       \
        _columnBinding = binding;                                   \
    }

#endif /* ALDBCodingMacros_Private_h */
