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

- (void)testInstanceMethodCategorySymbol {
    NSString *symbol = @"-[NSLocale(InternationalSupportExtensions) localizedStringForRegion:context:short:]";
    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol] == OBJC_SYMBOLS_SUCCESS);
    
    NSString *interfaceName = @"NSLocale(InternationalSupportExtensions)";
    NSMutableArray<DLObjectiveCMethod*> *listOfMethods = [[_objCSymbols methods] objectForKey:interfaceName];
    XCTAssertNotNil(listOfMethods);
    XCTAssertEqual([listOfMethods count], 1);
    
    DLObjectiveCMethod *objCMethod = [listOfMethods objectAtIndex:0];
    NSString *interfaceNameExpected = interfaceName;
    NSString *methodTypeExpected = @"-";
    NSArray<NSString*> *methodPartsExpected = @[@"localizedStringForRegion:", @"context:", @"short:"];
    XCTAssertEqualObjects(interfaceNameExpected, [objCMethod interfaceName]);
    XCTAssertEqualObjects(methodTypeExpected, [objCMethod methodType]);
    XCTAssertEqualObjects(methodPartsExpected, [objCMethod methodParts]);
}

//- (void)test_OBJC_IVAR_ {
//    NSString *symbol = @"_OBJC_IVAR_$_PHAssetPhotosOneUpProperties._variationSuggestionStates";
//    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol] == OBJC_SYMBOLS_SUCCESS);
//
//}

- (void)testSymbol__OBJC__CATEGORY {
    NSString *symbol = @"__OBJC_$_CATEGORY_NSMutableDictionary_$_AutoInsertEntry";
    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol] == OBJC_SYMBOLS_SUCCESS);
    XCTAssertTrue([_objCSymbols.categoryKeys containsObject:@"NSMutableDictionary(AutoInsertEntry)"]);
    XCTAssertEqualObjects(_objCSymbols.properName[@"NSMutableDictionary(AutoInsertEntry)"],@"NSMutableDictionary (AutoInsertEntry)");
    XCTAssertEqualObjects(_objCSymbols.filenames[@"NSMutableDictionary(AutoInsertEntry)"],@"NSMutableDictionary+AutoInsertEntry");
}

- (void)testSymbol__OBJC_PROTOCOL {
    NSString *symbol = @"__OBJC_PROTOCOL_$__ASWebAuthenticationSessionRequestHandling";
    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol] == OBJC_SYMBOLS_SUCCESS);
    XCTAssertTrue([_objCSymbols.protocolKeys containsObject:@"_ASWebAuthenticationSessionRequestHandling"]);
    XCTAssertEqualObjects(_objCSymbols.properName[@"_ASWebAuthenticationSessionRequestHandling"],@"_ASWebAuthenticationSessionRequestHandling");
    XCTAssertEqualObjects(_objCSymbols.filenames[@"_ASWebAuthenticationSessionRequestHandling"],@"_ASWebAuthenticationSessionRequestHandling");
}

- (void)testSymbol_OBJC_CLASS {
    NSString *symbol = @"_OBJC_CLASS_$_ASAuthorizationSecurityKeyPublicKeyCredentialAssertion";
    XCTAssertTrue([_objCSymbols addObjectiveCSymbol:symbol] == OBJC_SYMBOLS_SUCCESS);
    XCTAssertTrue([_objCSymbols.interfaceKeys containsObject:@"ASAuthorizationSecurityKeyPublicKeyCredentialAssertion"]);
    XCTAssertEqualObjects(_objCSymbols.properName[@"ASAuthorizationSecurityKeyPublicKeyCredentialAssertion"],@"ASAuthorizationSecurityKeyPublicKeyCredentialAssertion");
    XCTAssertEqualObjects(_objCSymbols.filenames[@"ASAuthorizationSecurityKeyPublicKeyCredentialAssertion"],@"ASAuthorizationSecurityKeyPublicKeyCredentialAssertion");
}

@end
