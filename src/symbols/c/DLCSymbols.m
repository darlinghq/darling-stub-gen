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

#import "DLCSymbols.h"

bool isValidCSymbol(NSString *symbol);

@implementation DLCSymbols

-(instancetype)init {
    _variables = [[NSMutableArray alloc] init];
    _functions = [[NSMutableArray alloc] init];
    return self;
}

-(DLCSymbolsResults)addCSymbol:(MKSectionSymbol*)symbol isExtern:(BOOL)isExtern {
    MKLCSection *loadCommand = symbol.section.value.loadCommand;
    NSString *section_name = loadCommand.sectname;
    NSString *segment_name = loadCommand.segname;
    NSString *symbol_name = symbol.name.value.string;
    
    if (isValidCSymbol(symbol_name)) {
        if ([segment_name  isEqualToString:@"__TEXT"]) {
            if ([section_name isEqualToString:@"__text"]) {
                [_functions addObject:[DLCFunction parseMethod:symbol_name]];
                return C_SYMBOLS_SUCCESS;
            } else if ([section_name isEqualToString:@"__const"]) {
                [_variables addObject:[DLCVariable parseVariable:symbol_name isConstant:YES isStatic:NO]];
                return C_SYMBOLS_SUCCESS;
            }
        } else if ([segment_name isEqualToString:@"__TEXT"]) {
            if ([section_name isEqualToString:@"__data"]) {
                [_variables addObject:[DLCVariable parseVariable:symbol_name isConstant:NO isStatic:NO]];
                return C_SYMBOLS_SUCCESS;
            }
        }
    }
    
    return C_SYMBOLS_NOT_VALID;
}

-(void)sortResults {
    
}

@end

bool isValidCSymbol(NSString *symbol) {
    const char* utf8String = [symbol UTF8String];
    
    for (int i=0; i < symbol.length; i++) {
        char curChar = utf8String[i];
        
        bool isNumber = '0' <= curChar && curChar <= '9';
        bool isLowerCase = 'a' <= curChar && curChar <= 'z';
        bool isUpperCase = 'A' <= curChar && curChar <= 'Z';
        bool isUnderline = curChar == '_';
        
        if (!isNumber && !isLowerCase && !isUpperCase & !isUnderline) {
            return false;
        }
    }
    
    return true;
}
