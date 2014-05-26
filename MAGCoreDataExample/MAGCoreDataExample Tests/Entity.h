//
//  Entity.h
//  MAGCoreDataExample
//
//  Created by Kroshmelot on 26.05.14.
//  Copyright (c) 2014 MadAppGang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Entity, Entity2;

@interface Entity : NSManagedObject

@property (nonatomic, retain) NSNumber * attr1;
@property (nonatomic, retain) NSNumber * attr2;
@property (nonatomic, retain) Entity *relationship;
@property (nonatomic, retain) Entity2 *relationship1;

@end
