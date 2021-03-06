//
//  NSManagedObject+MAGCoreData.m
//  TopMission
//
//  Created by Ievgen Rudenko on 8/30/13.
//  Copyright (c) 2013 MadAppGang. All rights reserved.
//
#import "NSManagedObject+MAGCoreData.h"
#import "MAGCoreData.h"
#import "ISO8601DateFormatter.h"
#import <objc/runtime.h>

static NSString const * kKeyMapKey = @"NSManagedObjectMagCoreDataMappingKey";
static NSString const * kRelationsKey = @"NSManagedObjectMagCoreDataRelationsKey";
static NSString const * kDatesFormatKey = @"NSManagedObjectMagCoreDataDatesFormatKey";
static NSString const * kDefaultDateFormatKey = @"NSManagedObjectMagCoreDataDefaultDateFormatKey";
static NSString const * kPrimaryKeyNameKey= @"NSManagedObjectMagCoreDataPrimaryKeyNameKey";
static NSString const * kUpdateDateKey= @"NSManagedObjectMagCoreDataUpdateDateKey";



@implementation NSManagedObject (MAGCoreData)


+ (NSDictionary *)keyMapping {
    return objc_getAssociatedObject(self, &kKeyMapKey);
}

+ (void)setKeyMapping:(NSDictionary *)keyMapping {
    objc_setAssociatedObject(self, &kKeyMapKey, keyMapping, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


+ (NSDictionary *)relationClasses {
    return objc_getAssociatedObject(self, &kRelationsKey);

}

+ (void)setRelationClasses:(NSDictionary *)newRelationClasses {
    objc_setAssociatedObject(self, &kRelationsKey, newRelationClasses, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NSDictionary *)dateFormats {
    return objc_getAssociatedObject(self, &kDatesFormatKey);
}

+ (void)setDateFormats:(NSDictionary *)datesFormat {
    objc_setAssociatedObject(self, &kDatesFormatKey, datesFormat, OBJC_ASSOCIATION_COPY_NONATOMIC);

}


+ (NSString *)defaultDateFormat {
    return objc_getAssociatedObject(self, &kDefaultDateFormatKey);
}

+ (void)setDefaultDateFormat:(NSString *)dateFormat {
    objc_setAssociatedObject(self, &kDefaultDateFormatKey, dateFormat, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


+ (id)primaryKeyName {
    return objc_getAssociatedObject(self, &kPrimaryKeyNameKey);
}

+ (void)setPrimaryKeyName:(id)primaryKey {
    objc_setAssociatedObject(self, &kPrimaryKeyNameKey, primaryKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)updateDateKeyName {
    return objc_getAssociatedObject(self, &kUpdateDateKey);
}

+ (void)setUpdateDateKeyName:(id)updateKeyName {
    objc_setAssociatedObject(self, &kUpdateDateKey, updateKeyName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


- (void)safeSetValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    [self safeSetValuesForKeysWithDictionary:keyedValues inContext:[MAGCoreData context]];
}

- (NSDate *)dateFromObject:(id)object forAttribute:(id)attribute{
    NSString *df = [[self class] defaultDateFormat];
    NSString *specificDF = [[self class] dateFormats][attribute];
    df = specificDF?specificDF:df;
    if (df) {
//                ISO8601 timezone +XX:XX not available on iOS<6.x, that is why using ISO8601 date formatter:
        if ([df rangeOfString:@"ZZZZZ"].location == NSNotFound) {
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = df;
            return  [dateFormatter dateFromString:object];
        } else {
            ISO8601DateFormatter *dateFormatter = [ISO8601DateFormatter new];
            return  [dateFormatter dateFromString:object];
        }
    }  else {
        //prevent from crash
        NSLog(@"Unable to parse date (no date format specified):%@",object);
        return nil;
    }

}

- (BOOL)shouldUpdateFromDictionary:(NSDictionary*)keyedValues {
    NSDictionary *mapping = [[self class] keyMapping];

    //check is update necessary
    id updateDateKey = [[self class] updateDateKeyName];
    id updateDateMappedKey = mapping && updateDateKey && mapping[updateDateKey]?mapping[updateDateKey]: nil;
    if (updateDateMappedKey) {
        NSDate *localUpdateDate = [self valueForKey:updateDateKey];
        NSDate *remoteUpdateDate = [self dateFromObject:keyedValues[updateDateMappedKey] forAttribute:updateDateKey];
        //if the same date or local date is later then prevent update
        if (localUpdateDate && [localUpdateDate compare:remoteUpdateDate] != NSOrderedAscending) {
            return NO;
        }
    }
    return YES;

}

- (void)safeSetValuesForKeysWithDictionary:(NSDictionary *)keyedValues inContext:(NSManagedObjectContext *)context {
    //fill attributes
    NSDictionary *attributes = [[self entity] attributesByName];
    NSDictionary *mapping = [[self class] keyMapping];

    //attributes
    if ([self shouldUpdateFromDictionary:keyedValues]) {
        for (NSString *attribute in attributes) {
            NSString *attributeKey = mapping?mapping[attribute]:attribute;
            id value = keyedValues[attributeKey];
            if (value == nil) {
                // Don't attempt to set nil, or you'll overwrite values in self that aren't present in keyedValues
                NSLog(@"MAGCoreData+NSManagedObjectContext: mapping lost for attribute:%@ for class %@",attribute, [self class]);
                continue;
            }
            NSAttributeType attributeType = [attributes[attribute] attributeType];
            if ([value isKindOfClass:[NSNull class]]) {
                value = nil;
            } else if ((attributeType == NSStringAttributeType) && ([value isKindOfClass:[NSNumber class]])) {
                value = [value stringValue];
            } else if (((attributeType == NSInteger16AttributeType) || (attributeType == NSInteger32AttributeType) || (attributeType == NSInteger64AttributeType) || (attributeType == NSBooleanAttributeType)) && ([value isKindOfClass:[NSString class]])) {
                value = @([value  integerValue]);
            } else if ((attributeType == NSFloatAttributeType) && ([value isKindOfClass:[NSString class]])) {
                value = @([value doubleValue]);
            } else if ((attributeType == NSDateAttributeType) && ([value isKindOfClass:[NSString class]])) {
                value = [self dateFromObject:value forAttribute:attribute];
            }
            [self setValue:value forKey:attribute];
        }
    }

    NSDictionary *relationsClasses = [[self class] relationClasses];
    for (NSString * relationName in [relationsClasses allKeys]) {
        NSString *relationKey = mapping?mapping[relationName]:relationName;
        id value = keyedValues[relationKey];
        if (value && [value isKindOfClass:[NSDictionary class]]) {
            [self createRelationshipForRelationName:relationName
                                        relationKey:relationKey
                                          withValue:value
                                          inContext:context];
        } else if (value && [value isKindOfClass:[NSArray class]]) {
            [self createRelationshipToManyForRelationName:relationName
                                        relationKey:relationKey
                                          withValue:value
                                          inContext:context];
        }
    }
}

- (void)createRelationshipToManyForRelationName:(id)relationName
                                   relationKey:(id)relationKey
                                     withValue:(id)value
                                     inContext:(NSManagedObjectContext*)context{
    for (NSDictionary *oneValue in value) {
        [self createRelationshipForRelationName:relationName
                                    relationKey:relationKey
                                      withValue:oneValue
                                      inContext:context];
    }
}

- (NSString *)firstLetterCap:(NSString*)string {
    NSString *firstCapChar = [[string substringToIndex:1] capitalizedString];
    NSString *cappedString = [string stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:firstCapChar];
    return cappedString;
}

- (void)addObject:(NSManagedObject*)obj toRelation:(NSString*)relation {
    NSSet *set = [self valueForKey:relation];
    if ([set isKindOfClass:[NSSet class]] || [set isKindOfClass:[NSOrderedSet class]]) {
        if (![set containsObject:obj]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"add%@Object:",[self firstLetterCap:relation]])
                       withObject:obj];
#pragma clang diagnostic pop
        }
    }
}

- (void)setObject:(NSManagedObject *)obj forRelation:(NSString*)relation {
    if ([self valueForKey:relation] != obj) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@:",[self firstLetterCap:relation]])
                   withObject:obj];
#pragma clang diagnostic pop
    }
}


- (void)createRelationshipForRelationName:(id)relationName relationKey:(id)relationKey withValue:(id)value inContext:(NSManagedObjectContext*)context {
    NSDictionary *relationsClasses = [[self class] relationClasses];
    NSRelationshipDescription *relationshipDescription = [[self entity] relationshipsByName][relationName];
    if (relationshipDescription) {
        Class objectClass = relationsClasses[relationName];
        //fill with recursion from dictionary
        NSManagedObject *object = [objectClass safeCreateOrUpdateWithDictionary:value inContext:context];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if (relationshipDescription.isToMany) {
            //the object not created, so everything ok
            [self addObject:object toRelation:relationName];
        } else {
            [self setObject:object forRelation:relationName];
        }
#pragma clang diagnostic pop
    }
}


#pragma mark - easy object manipulation
+ (instancetype)getOrCreateObjectForPrimaryKey:(id)primaryKey {
    return [self getOrCreateObjectForPrimaryKey:primaryKey inContext:[MAGCoreData context]];
}

+ (instancetype)getOrCreateObjectForPrimaryKey:(id)primaryKey inContext:(NSManagedObjectContext *)context {
    NSManagedObject *object = nil;
    if (primaryKey) object = [self firstWithKey:[self primaryKeyName] value:primaryKey inContext:context];
    if (object) {
        return object;
    } else {
        return [self createInContext:context];
    }
}


+ (instancetype)safeCreateOrUpdateWithDictionary:(NSDictionary *)keyedValues {
    return [self safeCreateOrUpdateWithDictionary:keyedValues inContext:[MAGCoreData context]];

}

+ (instancetype)safeCreateOrUpdateWithDictionary:(NSDictionary *)keyedValues inContext:(NSManagedObjectContext *)context {
    //createOrUpdate
    id pk = [self primaryKeyName];
    NSString *mappedPrimaryKey = pk?[self keyMapping][pk]: nil;
    id primaryKey = mappedPrimaryKey?keyedValues[mappedPrimaryKey]:nil;
    NSManagedObject *selfObject = [self getOrCreateObjectForPrimaryKey:primaryKey inContext:context];
    [selfObject safeSetValuesForKeysWithDictionary:keyedValues inContext:context];
    return selfObject;
}


+ (id)create {
    return [self createInContext:[MAGCoreData context]];
}

+ (id)createInContext:(NSManagedObjectContext *)context {
    NSParameterAssert(context);
    NSManagedObject *object = nil;
    object =  [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class) inManagedObjectContext:context];
    return object;
}

+ (instancetype)createFromDictionary:(NSDictionary *)dictionary {
    return [self createFromDictionary:dictionary inContext:[MAGCoreData context]];
}

+ (instancetype)createFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext*)context {
    NSParameterAssert(context);
    NSManagedObject * object = [self createInContext:context];
    [object safeSetValuesForKeysWithDictionary:dictionary];
    return object;
}

#pragma mark - fetching objects

+ (NSArray *)all {
    return [self allInContext:[MAGCoreData context]];
}

+ (NSArray *)allForPredicate:(NSPredicate *)predicate {
    return [self allForPredicate:predicate inContext:[MAGCoreData context]];
}

+ (NSArray *)allForPredicate:(NSPredicate *)predicate orderBy:(NSString *)key ascending:(BOOL)ascending {
    return [self allForPredicate:predicate orderBy:key ascending:ascending inContext:[MAGCoreData context]];
}

+ (NSArray *)allOrderedBy:(NSString *)key ascending:(BOOL)ascending {
    return [self allOrderedBy:key ascending:ascending inContext:[MAGCoreData context]];
}

+ (NSArray *)allInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    __block NSArray *ret = nil;
    ret = [context executeFetchRequest:request error:nil];
    return ret;
}

+ (NSArray *)allForPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    [request setPredicate:predicate];
    __block NSArray *ret = nil;
    ret = [context executeFetchRequest:request error:nil];
    return ret;
}

+ (NSArray *)allForPredicate:(NSPredicate *)predicate orderBy:(NSString *)key ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:ascending];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[sortDescriptor]];
    __block NSArray *ret = nil;
    ret = [context executeFetchRequest:request error:nil];
    return ret;
}

+ (NSArray *)allOrderedBy:(NSString *)key ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:ascending];
    [request setSortDescriptors:@[sortDescriptor]];
    __block NSArray *ret = nil;
    ret = [context executeFetchRequest:request error:nil];
    return ret;

}

+ (id)first {
    return  [self firstInContext:[MAGCoreData context]];
}

+ (id)firstWithKey:(NSString *)key value:(id)value {
    return [self firstWithKey:key value:value inContext:[MAGCoreData context]];
}


+ (id)firstInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    __block NSArray *values = nil;
    values = [context executeFetchRequest:request error:nil];
    if (values.count > 0) {
        return (NSManagedObject *)values[0];
    }
    return nil;
}

+ (id)firstWithKey:(NSString *)key value:(id)value inContext:(NSManagedObjectContext *)context {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    [request setPredicate:predicate];
    __block NSArray *values = nil;
    values = [context executeFetchRequest:request error:nil];
    if (values.count > 0) {
        return (NSManagedObject *)values[0];
    }
    return nil;
}

#pragma mark - deleting objects

+ (void)deleteAll {
    [self deleteAllInContext:[MAGCoreData context]];
}

+ (void)deleteAllInContext:(NSManagedObjectContext *)context {
    NSArray *objects = [self allInContext:context];
    for (NSManagedObject *object in objects)
        [context deleteObject:object];
}

- (void)delete {
    [self.managedObjectContext deleteObject:self];
}

#pragma mark - refreshing object

- (void)refreshMerging:(BOOL)merging {
    [self.managedObjectContext refreshObject:self mergeChanges:merging];
}


@end
