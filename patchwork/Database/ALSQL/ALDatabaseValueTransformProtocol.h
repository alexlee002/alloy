//
//  ALDatabaseValueTransformProtocol.h
//  patchwork
//
//  Created by Alex Lee on 02/05/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ALDatabaseValueTransformProtocol <NSObject>

- (id)al_valueTransformToDatabase;
- (id)al_objectTransformFromDatabase;

@end
