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

#define create_array_if_key_does_not_exist(class_name,list,dictionary) dictionary[class_name]; \
if (list == nil) { \
    list = [[NSMutableArray alloc] init]; \
    dictionary[class_name] = list; \
}

const NSString *OBJC_CATEGORY = @"__OBJC_$_CATEGORY_";
const NSString *OBJC_CLASS = @"_OBJC_CLASS_$_";
const NSString *OBJC_CLASS_METHODS = @"__OBJC_$_CLASS_METHODS_";
const NSString *OBJC_CLASS_PROP_LIST = @"__OBJC_$_CLASS_PROP_LIST_";
const NSString *OBJC_CLASS_PROTOCOLS = @"__OBJC_CLASS_PROTOCOLS_$_";
const NSString *OBJC_CLASS_RO = @"__OBJC_CLASS_RO_$_";
const NSString *OBJC_INSTANCE_VARIABLES = @"__OBJC_$_INSTANCE_VARIABLES_";
const NSString *OBJC_INSTANCE_METHODS = @"__OBJC_$_INSTANCE_METHODS_";
const NSString *OBJC_IVAR = @"_OBJC_IVAR_$_";
const NSString *OBJC_LABEL_PROTOCOL = @"__OBJC_LABEL_PROTOCOL_$_";
const NSString *OBJC_METACLASS = @"_OBJC_METACLASS_$_";
const NSString *OBJC_METACLASS_RO = @"__OBJC_METACLASS_RO_$_";
const NSString *OBJC_PROP_LIST = @"__OBJC_$_PROP_LIST_";
const NSString *OBJC_PROTOCOL = @"__OBJC_PROTOCOL_$_";
const NSString *OBJC_PROTOCOL_CLASS_METHODS = @"__OBJC_$_PROTOCOL_CLASS_METHODS_";
const NSString *OBJC_PROTOCOL_INSTANCE_METHODS = @"__OBJC_$_PROTOCOL_INSTANCE_METHODS_";
const NSString *OBJC_PROTOCOL_INSTANCE_METHODS_OPT = @"__OBJC_$_PROTOCOL_INSTANCE_METHODS_OPT_";
const NSString *OBJC_PROTOCOL_METHOD_TYPES = @"__OBJC_$_PROTOCOL_METHOD_TYPES_";
const NSString *OBJC_PROTOCOL_REFERENCE = @"__OBJC_PROTOCOL_REFERENCE_$_";
const NSString *OBJC_PROTOCOL_REFS = @"__OBJC_$_PROTOCOL_REFS_";

const NSString *CPP_SYMBOL_IDENTIFIER = @"__Z";

const NSSet<NSString*> *backlistedObjC = nil;

bool isValidCMethod(NSString *symbol);
void createBlacklistedSymbols(void);

@implementation DLLibraryParser

-(instancetype)initWithArguments:(DLArgumentParser*)arugmentParser {
    _arguments = arugmentParser;
    dependiciesList = [[NSMutableArray alloc] init];
    
    _classnameObjC = [[NSMutableSet alloc] init];
    _protocolObjC = [[NSMutableSet alloc] init];
    _methodsObjC = [[NSMutableDictionary alloc] init];
    _variableObjC = [[NSMutableDictionary alloc] init];
    
    functionsC = [[NSMutableArray alloc] init];
    _functionCPP =  [[NSMutableArray alloc] init];
    
    _localIgnoreSymbols = [[NSMutableArray alloc] init];
    _localUnknownSymbols = [[NSMutableArray alloc] init];
    _externalSymbols = [[NSMutableArray alloc] init];
    _undefinedSymbols = [[NSMutableArray alloc] init];
    
    createBlacklistedSymbols();
    
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
                        
            if ([name hasPrefix:@"__OBJC"] || [name hasPrefix:@"_OBJC"]) {
                if ([name hasPrefix:(NSString*)OBJC_IVAR]) {
                    DLObjectiveCIVar *currentObjCVariable = [DLObjectiveCIVar parseVariable:name];
                    NSMutableArray<DLObjectiveCIVar*> *listOfVariables = create_array_if_key_does_not_exist(currentObjCVariable.className,listOfVariables,_variableObjC);
                    [listOfVariables addObject:currentObjCVariable];
                
                } else if ([name hasPrefix:(NSString*)OBJC_CLASS]) {
                    [_classnameObjC addObject: [name substringFromIndex:[OBJC_CLASS length]]];
                
                } else if ([name hasPrefix:(NSString*)OBJC_CLASS_RO]) {
                    [_classnameObjC addObject: [name substringFromIndex:[OBJC_CLASS_RO length]]];
                
                } else if ([name hasPrefix:(NSString*)OBJC_PROTOCOL]) {
                    NSString *symbol = [name substringFromIndex:[OBJC_PROTOCOL length]];
                    if ([backlistedObjC containsObject:symbol]) {
                        [_localIgnoreSymbols addObject:name];
                        continue;
                    }
                    
                    [_protocolObjC addObject: symbol];
                
                } else if ([name hasPrefix:(NSString*)OBJC_PROP_LIST] || [name hasPrefix:(NSString*)OBJC_INSTANCE_VARIABLES]
                           || [name hasPrefix:(NSString*)OBJC_INSTANCE_METHODS] || [name hasPrefix:(NSString*)OBJC_CLASS_METHODS]
                           || [name hasPrefix:(NSString*)OBJC_METACLASS] || [name hasPrefix:(NSString*)OBJC_PROTOCOL_INSTANCE_METHODS]
                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_INSTANCE_METHODS_OPT] || [name hasPrefix:(NSString*)OBJC_PROTOCOL_METHOD_TYPES]
                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_REFS] || [name hasPrefix:(NSString*)OBJC_CLASS_PROTOCOLS]
                           || [name hasPrefix:(NSString*)OBJC_LABEL_PROTOCOL]
                           || [name hasPrefix:(NSString*)OBJC_CATEGORY] || [name hasPrefix:(NSString*)OBJC_CLASS_PROP_LIST]
                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_CLASS_METHODS] || [name hasPrefix:(NSString*)OBJC_METACLASS_RO]
                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_REFERENCE]) {
                    [_localIgnoreSymbols addObject:name];
                    
                // For debugging purposes, lets keeps the remaining symbols that are not gathered in the other if conditions
                // in unknownSymbols.
                } else {
                    [_localUnknownSymbols addObject:name];
                }
            
            // If Objective C class/instance method
            } else if ([name hasPrefix:@"+["] || [name hasPrefix:@"-["]) {
                DLObjectiveCMethod *currentObjCMethod = [DLObjectiveCMethod parseMethod:name];
                NSMutableArray<DLObjectiveCMethod*> *listOfMethods = create_array_if_key_does_not_exist(currentObjCMethod.className,listOfMethods,_methodsObjC);
                [listOfMethods addObject:currentObjCMethod];

            // For symbols we don't care about, we will store them in ignoreSymbols
            } else if ([name containsString:@"block_invoke"] || [name containsString:@"___block_literal_global"]
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
    
    for (NSString *key in _methodsObjC) {
        [_methodsObjC[key] sortUsingSelector:@selector(compare:)];
    }
    
    for (NSString *key in _variableObjC) {
        [_variableObjC[key] sortUsingSelector:@selector(compare:)];
    }
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

void createBlacklistedSymbols() {
    if (backlistedObjC == nil) {
        backlistedObjC = [NSSet setWithObjects:
            @"NSCoding",
            @"NSCopying",
            @"NSMutableCopying",
            @"NSObject",
            @"NSSecureCoding",
            nil];
    }
}
