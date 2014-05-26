//
//  MAGCoreDataExample_Tests.m
//  MAGCoreDataExample Tests
//
//  Created by Kroshmelot on 26.05.14.
//  Copyright (c) 2014 MadAppGang. All rights reserved.
//

#define EXP_SHORTHAND
#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+MAGCoreData.h"

#import "MAGCoreData.h"

#import "Entity.h"
//#import "Expecta.h"

@interface MAGCoreDataExample_Tests : XCTestCase

@end

@implementation MAGCoreDataExample_Tests

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

- (void)testIfSingeltonExist {
    XCTAssertNotNil([MAGCoreData instance], @"instance is nil");
}

- (void)testIfContextExist {
//    XCTAssertNotNil([MAGCoreData context], @"context is nil");/////?????????
}

- (void)testPrepeareCoreData {
    XCTAssertNil([MAGCoreData prepareCoreData], @"core data is not prepeared");
}


- (void)testIfPrivateContextCreated {
    XCTAssertNotNil([MAGCoreData createPrivateContext], @"no private context");
}


- (void)testIfEntityCreated {
    [MAGCoreData deleteStorage];
    [MAGCoreData prepareCoreData];
    Entity *entity = [Entity create];
    XCTAssertNotNil(entity);
    [Entity deleteAll];
    
}

/*- (void)testSingeltonCanBeCreate {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    expect([MAGCoreData instance]).toNot.beNil();
}*/

@end
