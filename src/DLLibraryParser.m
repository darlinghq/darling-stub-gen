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

#import "DLLibraryParser.h"

#import <mach-o/nlist.h>

const NSString *CPP_SYMBOL_IDENTIFIER = @"__Z";

bool isValidCMethod(NSString *symbol);
void createBlacklistedSymbols(void);

@implementation DLLibraryParser

-(instancetype)initWithArguments:(DLArgumentParser*)arugmentParser {
    _arguments = arugmentParser;
    dependiciesList = [[NSMutableArray alloc] init];
    
    _objCSymbols = [[DLObjectiveCSymbols alloc] init];
    
    functionsC = [[NSMutableArray alloc] init];
    _functionCPP =  [[NSMutableArray alloc] init];
    
    _localIgnoreSymbols = [[NSMutableArray alloc] init];
    _localUnknownSymbols = [[NSMutableArray alloc] init];
    _externalSymbols = [[NSMutableArray alloc] init];
    _undefinedSymbols = [[NSMutableArray alloc] init];
    
    return self;
}

-(void)parseCurrentMachOImage:(MKMachOImage*)image {
    NSArray<MKLoadCommand*> *loadCommands = image.loadCommands;
    for (MKLoadCommand *loadCommand in loadCommands) {
        if ([loadCommand class] == [MKLCIDDylib class]) {
            MKLCIDDylib *idDylib = (MKLCIDDylib*)loadCommand;
            _mainImage = [[DLMainImage alloc] initWithMainDylib:idDylib];
        }
    }
}

-(void)parseDependentLibraryWithMachOImage:(MKMachOImage*)image {
    NSMutableArray<NSString*> *listOfDependicies = [[NSMutableArray alloc] init];
    
    for (MKResult<MKDependentLibrary*> *dependentLibraryResult in image.dependentLibraries) {
        MKDependentLibrary* dependentLibrary = dependentLibraryResult.value;
        if (dependentLibrary != nil) {
            NSString* libraryName = dependentLibrary.name;
            BOOL upward = dependentLibrary.upward;
            BOOL rexported = dependentLibrary.rexported;
            BOOL weak = dependentLibrary.weak;
            
            [listOfDependicies addObject:libraryName];
        }
    }
}

-(void) parseSymbolWithMachOImage:(MKMachOImage*)image {    
    MKResult<MKSymbolTable*> *symbolTableResult = image.symbolTable;
    MKSymbolTable* symbolTable = symbolTableResult.value;
    
    if (symbolTable != nil) {
        NSRange localRange = symbolTable.localSymbols;
        for (NSUInteger i = localRange.location; i < localRange.length; i++) {
            MKSectionSymbol *symbol = [symbolTable.symbols objectAtIndex: localRange.location+i];
            NSString *name = symbol.name.value.string;

            ObjectiveCSymbolsResults objCResult = [_objCSymbols addObjectiveCSymbol:name];
            if (objCResult != OBJC_SYMBOLS_NOT_VALID) {
                continue;
            }

            // For symbols we don't care about, we will store them in ignoreSymbols
            if ([name containsString:@"block_invoke"] || [name containsString:@"___block_literal_global"]
                       || [name containsString:@"___Block_byref_object_dispose_"] || [name containsString:@"___Block_byref_object_copy_"]
                       || [name containsString:@"GCC_except_table"] || [name containsString:@"___copy_helper_block"]
                       || [name containsString:@"___destroy_helper_block"]) {
                [_localIgnoreSymbols addObject:name];

            } else if ([name hasPrefix:(NSString*)CPP_SYMBOL_IDENTIFIER]) {
                [_functionCPP addObject:name];

            } else if (isValidCMethod(name)) {
                [functionsC addObject:name];

            // If we are not sure what the symbol is suppose to be, we will store them in the unknownSymbols
            } else {
                [_localUnknownSymbols addObject:name];
            }
        }
        
        NSRange externalSymbols = symbolTable.externalSymbols;
        for (NSUInteger i = externalSymbols.location; i < externalSymbols.length; i++) {
            MKSectionSymbol *symbol = [symbolTable.symbols objectAtIndex: localRange.location+i];
            NSString *name = symbol.name.value.string;
            
            [_externalSymbols addObject:name];
        }
        
        NSRange undefinedSymbols = symbolTable.undefinedSymbols;
        for (NSUInteger i = undefinedSymbols.location; i < undefinedSymbols.length; i++) {
            MKSectionSymbol *symbol = [symbolTable.symbols objectAtIndex: localRange.location+i];
            NSString *name = symbol.name.value.string;
            
            [_undefinedSymbols addObject:name];
        }
    }
    
    [functionsC sortUsingSelector:@selector(compare:)];
    [_localIgnoreSymbols sortUsingSelector:@selector(compare:)];
    [_localUnknownSymbols sortUsingSelector:@selector(compare:)];
    [_externalSymbols sortUsingSelector:@selector(compare:)];
    [_undefinedSymbols sortUsingSelector:@selector(compare:)];
}

@end

bool isValidCMethod(NSString *symbol) {
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
