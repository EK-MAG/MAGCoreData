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

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSingeltonCanBeCreate {
    expect([MAGCoreData instance]).toNot.beNil();
}

- (void)testSingeltonDidCreate {
    XCTAssertEqualObjects([MAGCoreData instance], [MAGCoreData instance], @"singelton didn't created");
}

- (void)testOnlyOneInstanceSingeltonDidCreate {
    XCTAssertEqualObjects([MAGCoreData instance], [MAGCoreData new], @"can be crated more than one instance singelton");
}

- (void)testPrepeareCoreData {
    NSError *error = [MAGCoreData prepareCoreData];
    XCTAssertNil(error, @"core data didn't prepeared");
}

- (void)testCanCreateTestEntity {
    [self prepareModel];

    TestEntity *object = [TestEntity create];

    XCTAssertNotNil(object, @"mananged object didn't created");

    [self clearTestEntity];
}

- (void)testWriteDataToTestEntity {
    NSString *testString = [TestEntity entityName];
    [self createTestEntityWithName:testString];

    [[MAGCoreData context] reset];

    TestEntity *object = [TestEntity getOrCreateObjectForPrimaryKey:[testString copy]];

    XCTAssertTrue([object.name isEqualToString:[testString copy]]);

    [self clearTestEntity];
}

- (void)testDeleteDataFromTestEntity {
    NSString *testString = [TestEntity entityName];
    [self createTestEntityWithName:testString];

    TestEntity *object = [TestEntity getOrCreateObjectForPrimaryKey:[testString copy]];
    [object delete];
    [MAGCoreData save];

    [[MAGCoreData context] reset];

    object = [TestEntity getOrCreateObjectForPrimaryKey:[testString copy]];

    XCTAssertNil(object.name);

    [self clearTestEntity];
}


#pragma mark - Prepare Model
- (void)prepareModel {
    [MAGCoreData prepareCoreData];
}

- (void)createTestEntityWithName:(NSString *)testString {
    [self prepareModel];

    TestEntity *object = [TestEntity create];
    [TestEntity setPrimaryKeyName:@"name"];

    object.name = [testString copy];

    [MAGCoreData save];
}

- (void)clearTestEntity {
    [TestEntity deleteAll];
}


@end
