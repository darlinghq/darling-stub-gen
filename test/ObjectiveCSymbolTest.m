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
#import "DLObjectiveCSymbols.h"

@interface ObjectiveCSymbolTest : XCTestCase

@end

@implementation ObjectiveCSymbolTest {
    DLObjectiveCSymbols *_objCSymbols;
}

- (void)setUp {
    _objCSymbols = [[DLObjectiveCSymbols alloc] init];
}

- (void)tearDown {}

- (void)testCategorySymbol {
    NSString *symbol = @"-[NSLocale(InternationalSupportExtensions) localizedStringForRegion:context:short:]";
    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol]);
    
    NSString *interfaceName = @"NSLocale(InternationalSupportExtensions)";
    NSMutableArray<DLObjectiveCMethod*> *listOfMethods = [[_objCSymbols methods] objectForKey:interfaceName];
    XCTAssertNotNil(listOfMethods);
    XCTAssertEqual([listOfMethods count], 1);
    
    NSString *expectedFileName = @"NSLocale+InternationalSupportExtensions";
    XCTAssertEqualObjects(expectedFileName, [[_objCSymbols filenames] objectForKey:interfaceName]);
    
    DLObjectiveCMethod *objCMethod = [listOfMethods objectAtIndex:0];
    NSString *interfaceNameExpected = interfaceName;
    NSString *methodTypeExpected = @"-";
    NSArray<NSString*> *methodPartsExpected = @[@"localizedStringForRegion:", @"context:", @"short:"];
    XCTAssertEqualObjects(interfaceNameExpected, [objCMethod interfaceName]);
    XCTAssertEqualObjects(methodTypeExpected, [objCMethod methodType]);
    XCTAssertEqualObjects(methodPartsExpected, [objCMethod methodParts]);
}

- (void)testIVarSymbol {
    NSString *symbol = @"_OBJC_IVAR_$_PHAssetPhotosOneUpProperties._variationSuggestionStates";
    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol]);
    
}

@end
