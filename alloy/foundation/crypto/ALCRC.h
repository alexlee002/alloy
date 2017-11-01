//
//  CRC.h
//  patchwork
//
//  Created by Alex Lee on 4/15/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

// Title: CRC Category for NSData
// Post by: rgronlie on February 02, 2010, 10:42:18 PM
// Reference: http://classroomm.com/objective-c/index.php?action=printpage;topic=2891.0

#import <Foundation/Foundation.h>

@interface NSData (AL_CRC32)

-(uint32_t)al_crc32;
-(uint32_t)al_crc32WithSeed:(uint32_t)seed;
-(uint32_t)al_crc32UsingPolynomial:(uint32_t)poly;
-(uint32_t)al_crc32WithSeed:(uint32_t)seed usingPolynomial:(uint32_t)poly;

@end
