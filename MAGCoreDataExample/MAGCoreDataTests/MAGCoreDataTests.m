//
//  MAGCoreDataTests.m
//  MAGCoreDataTests
//
//  Created by Dakhno Aleksandr on 5/24/14.
//  Copyright (c) 2014 MadAppGang. All rights reserved.
//

#define EXP_SHORTHAND
#import "Expecta.h"

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "MAGCoreData.h"
#import "NSManagedObject+MAGCoreData.h"
#import "TestEntity.h"

@interface MAGCoreDataTests : XCTestCase

@end

@implementation MAGCoreDataTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)tearDown {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test public API core data wrapper

- (void)testSingeltonCanBeCreate {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    expect([MAGCoreData instance]).toNot.beNil();
}

- (void)testSingeltonDidCreate {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    expect([MAGCoreData instance]).to.beIdenticalTo([MAGCoreData instance]);
}

- (void)testOnlyOneInstanceSingeltonDidCreate {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    expect([MAGCoreData instance]).to.beIdenticalTo([MAGCoreData new]);
}

- (void)testModelCanBePrepare {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    expect([MAGCoreData prepareCoreData]).to.beNil();
}

- (void)testModelCanBeClear {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self prepareModel];

    NSManagedObjectContext *context = [MAGCoreData context];

    expect(context).toNot.beNil();

    [[MAGCoreData instance] close];

    context = [MAGCoreData context];

    expect(context).to.beNil();
}

#pragma mark - Test Entity

- (void)testCanCreateTestEntity {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self prepareModel];

    TestEntity *object = [TestEntity create];

    expect(object).toNot.beNil();

    [self clearTestEntity];
}

- (void)testWriteDataToTestEntity {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSString *testString = [TestEntity entityName];

    [self createTestEntityWithNameValue:testString];

    // clear current context
    [[MAGCoreData context] reset];

    // get created entity from base
    TestEntity *object = [self entityForNameValue:testString];

    expect(object).toNot.beNil();
    expect(object.name).to.equal(testString);

    [self clearTestEntity];
}

- (void)testCanCreateTestEntityWithDictionary {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [MAGCoreData prepareCoreData];

    NSString *testString = [TestEntity entityName];

    NSDictionary *dictionary = @{
            @"name" : testString
    };

    // verify that no entity with this value in base
    TestEntity *object = [self entityForNameValue:testString];
    expect(object).to.beNil();

    [TestEntity safeCreateOrUpdateWithDictionary:dictionary];

    // clear current context
    [[MAGCoreData context] reset];

    // get saved entity
    object = [self entityForNameValue:testString];

    expect(object).toNot.beNil();
    expect(object.name).to.equal(testString);

    [self clearTestEntity];
}

- (void)testDeleteDataFromTestEntity {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSString *testString = [TestEntity entityName];

    // create new entity
    [self createTestEntityWithNameValue:testString];

    // get new created entity
    TestEntity *object = [self entityForNameValue:testString];
    expect(object).toNot.beNil();

    [object delete];
    [MAGCoreData save];

    // clear current context
    [[MAGCoreData context] reset];

    // verify that no one entity exist in base
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", testString];
    NSArray *expectedObjects = [TestEntity allForPredicate:predicate];
    expectedObjects = [TestEntity allForPredicate:predicate];

    expect(expectedObjects.count).to.equal(0);

    [self clearTestEntity];
}

#pragma mark - Prepare Model
- (void)prepareModel {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [MAGCoreData prepareCoreData];
}

- (void)createTestEntityWithNameValue:(NSString *)testString {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self prepareModel];

    TestEntity *object = [TestEntity create];
    object.name = [testString copy];

    [MAGCoreData save];
}

- (TestEntity *)entityForNameValue:(NSString *)value {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", value];
    NSArray *expectedObjects = [TestEntity allForPredicate:predicate];
    return expectedObjects.count > 0 ? expectedObjects[0] : nil;
}

- (void)clearTestEntity {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [TestEntity deleteAll];
}


@end
