//
//  ALDBLog_private.h
//  patchwork
//
//  Created by Alex Lee on 03/01/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef ALDBLog_private_h
#define ALDBLog_private_h

#import "ALLogger.h"

// for Patchwork only
#if ALDB_DEBUG_LOG_OFF
#define _ALDBLog(...)    do{}while(0)
#else
#define _ALDBLog         ALLogVerbose
#endif


#endif /* ALDBLog_private_h */
