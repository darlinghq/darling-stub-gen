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

#import "DLSwiftSymbols.h"

enum SwiftPrefixEnum {
    PREFIX_SWIFT_UNKNOWN,
    PREFIX_SWIFT_4,
    PREFIX_SWIFT_4X,
    PREFIX_SWIFT_5PLUS
};

static NSArray<NSString*> *swiftPrefixes;
static NSDictionary<NSString*,NSNumber*> *swiftPrefixToEnum;

BOOL isNumber(NSString *strTemp) {
    NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [strTemp rangeOfCharacterFromSet:nonNumberSet];
    return r.location == NSNotFound && strTemp.length > 0;
}

@implementation DLSwiftSymbols {
    NSString *_mangledSymbolTemp;
    enum SwiftPrefixEnum _prefixType;
}

+(void)initialize {
    // Taken from Swift Demangler.cpp
    swiftPrefixes = @[
        /* Swift 4 */     @"_T0",
        /* Swift 4.x */   @"$S", @"_$S",
        /* Swift 5+ */    @"$s", @"_$s"
    ];
    
    swiftPrefixToEnum = @{
        @"_T0": [NSNumber numberWithInt:PREFIX_SWIFT_4],
        @"$S": [NSNumber numberWithInt:PREFIX_SWIFT_4X],
        @"_$S": [NSNumber numberWithInt:PREFIX_SWIFT_4X],
        @"$s": [NSNumber numberWithInt:PREFIX_SWIFT_5PLUS],
        @"_$s": [NSNumber numberWithInt:PREFIX_SWIFT_5PLUS]
    };
}

-(instancetype)initWithSymbol:(NSString*)symbol {
    _mangledSymbol = symbol;
    _demangledSymbol = nil;
    
    _mangledSymbolTemp = symbol != nil ? symbol : [[NSString alloc] init];
    _prefixType = PREFIX_SWIFT_UNKNOWN;
    return self;
}

+(BOOL)isSymbolSwift:(NSString*)symbol {
    DLSwiftSymbols *swiftSymbols = [[DLSwiftSymbols alloc] initWithSymbol:symbol];
    return [swiftSymbols isValidSwiftPrefix];
}

+(void)demanageSwiftSymbol:(NSString*)symbol {
    DLSwiftSymbols *swiftSymbols = [[DLSwiftSymbols alloc] initWithSymbol:symbol];
    if ([swiftSymbols isValidSwiftPrefix]) {
        NSString *strTemp = [swiftSymbols getFirstSymbolFromTemp];
        
        if (isNumber(strTemp)) {
            // The first symbols is generaly the library name
            [swiftSymbols setLibraryName: [swiftSymbols extractSymbol]];
            NSLog(@"%@", swiftSymbols.libraryName);
        }
        
        strTemp = [swiftSymbols getFirstSymbolFromTemp];
        while ([strTemp length] > 0) {
            if (isNumber(strTemp)) {
                [swiftSymbols setFunctionName: [swiftSymbols extractSymbol]];
                NSLog(@"%@", swiftSymbols.libraryName);
            }
            
            strTemp = [swiftSymbols getFirstSymbolFromTemp];
        }
    }
}

-(void)setLibraryName:(NSString * _Nonnull)libraryName {
    _libraryName = libraryName;
}

-(void)setFunctionName:(NSString * _Nonnull)functionName {
    _functionName = functionName;
}

-(NSString*)getFirstSymbolFromTemp {
    return [_mangledSymbolTemp substringWithRange:NSMakeRange(0, 1)];
}

-(BOOL)isValidSwiftPrefix {
    if ([_mangledSymbolTemp length] == 0) {
        return NO;
    }
    
    for (NSString *prefix in swiftPrefixes) {
        if ([_mangledSymbolTemp hasPrefix:prefix]) {
            _mangledSymbolTemp = [_mangledSymbolTemp substringFromIndex:[prefix length]];
            _prefixType = [[swiftPrefixToEnum objectForKey:prefix] intValue];
            return YES;
        }
    }
    
    return NO;
}

-(NSString*)extractSymbol {
    NSMutableString *numberString = [[NSMutableString alloc] init];
    
    for (int i=0; i < [_mangledSymbol length]; i++) {
        NSString *strTemp = [_mangledSymbolTemp substringWithRange:NSMakeRange(i, 1)];
        
        if (!isNumber(strTemp)) {
            break;
        }
        
        [numberString appendString:strTemp];
    }
    
    NSNumberFormatter *numberFormater = [[NSNumberFormatter alloc] init];
    numberFormater.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *symbolSize = [numberFormater numberFromString:numberString];
    _mangledSymbolTemp = [_mangledSymbolTemp substringFromIndex:[numberString length]];
    
    NSString *symbolReturn = [_mangledSymbolTemp substringToIndex:[symbolSize intValue]];
    _mangledSymbolTemp = [_mangledSymbolTemp substringFromIndex:[symbolSize intValue]];
    return symbolReturn;
}

@end
