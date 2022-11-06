/*
 This file is part of Darling.

 Copyright (C) 2021 Darling Team

 Darling is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Darling is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <XCTest/XCTest.h>
#import "symbols/swift/DLSwiftSymbols.h"

@interface SwiftSymbolTest : XCTestCase

@end

@implementation SwiftSymbolTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testIsSymbolSwift {
    BOOL result = [DLSwiftSymbols isSymbolSwift:@"_$s18SwiftFrameworkTest12mathArgumentyyF"];
    XCTAssert(result);
}

/**
 DLSwiftSymbols should produce the following
 func swiftFunctionNoArguments() {}
 */
- (void)testDemanageFunctionNoArgumentsSymbol {
    [DLSwiftSymbols demanageSwiftSymbol:@"_$s18SwiftFrameworkTest24swiftFunctionNoArgumentsyyF"];
}

/**
 func swiftFunction3Arguments(firstArgument:Int8, secondArgument: Int16, thirdArgument: Int32) {}
 */
- (void)testDemangleFunctionThreeArgumentsSymbol {
    [DLSwiftSymbols demanageSwiftSymbol:@"_$s18SwiftFrameworkTest23swiftFunction3Arguments13firstArgument06secondH005thirdH0ys4Int8V_s5Int16Vs5Int32VtF"];
}

- (void)testDemanageFunctionReturnInt32 {
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
