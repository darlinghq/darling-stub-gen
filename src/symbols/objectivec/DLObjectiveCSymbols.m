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

#import <Foundation/Foundation.h>

#import "DLObjectiveCSymbols.h"

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

const NSString *OBJC_ONE_UNDERSCORE_IDENTIFIER = @"_OBJC";
const NSString *OBJC_TWO_UNDERSCORES_IDENTIFIER = @"__OBJC";
const NSString *OBJC_CLASS_METHOD_IDENTIFIER = @"+[";
const NSString *OBJC_INSTANCE_METHOD_IDENTIFIER = @"-[";

#import "NSMutableDictionary+AutoInsertEntry.h"

static NSSet<NSString*> *backlisted = nil;

NSString *determineFileName(NSString *interfaceName);
void createBlacklistedSymbols(void);

/**
 For now, this method only handles converting NSLocale(InternationalSupportExtensions) to NSLocale+InternationalSupportExtensions.
 */
NSString *determineFileName(NSString *interfaceName) {
    NSArray *splitName = [interfaceName componentsSeparatedByString:@"("];
    if ([splitName count] != 2) {
        return interfaceName;
    }
    
    NSString *className = [splitName objectAtIndex:0];
    NSString *categoryName = [splitName objectAtIndex:1];
    if (![categoryName hasSuffix:@")"]) {
        return interfaceName;
    }
    
    categoryName = [categoryName substringToIndex: [categoryName length]-1];
    return [NSString stringWithFormat:@"%@+%@", className, categoryName];
}

void createBlacklistedSymbols() {
    if (backlisted == nil) {
        backlisted = [NSSet setWithObjects:
            @"NSCoding",
            @"NSCopying",
            @"NSMutableCopying",
            @"NSObject",
            @"NSSecureCoding",
            nil];
    }
}

@implementation DLObjectiveCSymbols

-(instancetype)init {
    _filenames = [[NSMutableDictionary alloc] init];
    
    _categoryKeys = [[NSMutableSet alloc] init];
    _interfaceKeys = [[NSMutableSet alloc] init];
    _protocolKeys = [[NSMutableSet alloc] init];
    
    _methods = [[NSMutableDictionary alloc] init];
    _variables = [[NSMutableDictionary alloc] init];
    _keyToProperName = [[NSMutableDictionary alloc] init];
    
    _ignored = [[NSMutableArray alloc] init];
    
    static dispatch_once_t once_initialize_blacklist;
    dispatch_once(&once_initialize_blacklist, ^{ createBlacklistedSymbols();
    });
    
    return self;
}

-(ObjectiveCSymbolsResults)addObjectiveCSymbol:(NSString*)symbol {
    if ([symbol hasPrefix:(NSString*)OBJC_CLASS_METHOD_IDENTIFIER]
        || [symbol hasPrefix:(NSString*)OBJC_INSTANCE_METHOD_IDENTIFIER]) {
        DLObjectiveCMethod *currentObjCMethod = [DLObjectiveCMethod parseMethod:symbol];
        NSString *interfaceName = currentObjCMethod.interfaceName;
        
        [_filenames setObject:determineFileName(interfaceName) forKey:interfaceName];
        
//        // If the string contains a '(' and ')', we'll assume that it is a category
//        if ([interfaceName containsString:@"("] && [interfaceName containsString:@")"]) {
//            [_categoryKeys addObject:interfaceName];
//            [_keyToProperName setObject:interfaceName forKey:interfaceName];
//        } else {
//            [_interfaceKeys addObject:interfaceName];
//            [_keyToProperName setObject:interfaceName forKey:interfaceName];
//        }
        
        NSMutableArray<DLObjectiveCMethod*> *listOfMethods = [_methods objectForKey:interfaceName createIfNoneExist:initalizeNSMutableArray];
        [listOfMethods addObject:currentObjCMethod];
        
        return OBJC_SYMBOLS_SUCCESS;
    }
    
    else if ([symbol hasPrefix:(NSString*)OBJC_IVAR]) {
        DLObjectiveCIVar *currentObjCVariable = [DLObjectiveCIVar parseVariable:symbol];
        NSString *className = currentObjCVariable.className;
        
        [_interfaceKeys addObject:className];
        NSMutableArray<DLObjectiveCIVar*> *listOfVariables = [_variables objectForKey:className createIfNoneExist:initalizeNSMutableArray];
        [listOfVariables addObject:currentObjCVariable];
        
        return OBJC_SYMBOLS_SUCCESS;
    }
    
    else if ([symbol hasPrefix:(NSString*)OBJC_CLASS]) {
        NSString *symbolName = [symbol substringFromIndex:[OBJC_CLASS length]];
        [_interfaceKeys addObject: symbolName];
        [_keyToProperName setObject:symbolName forKey:symbolName];
        return OBJC_SYMBOLS_SUCCESS;
    }
    
    else if ([symbol hasPrefix:(NSString*)OBJC_CLASS_RO]) {
        NSString *symbolName = [symbol substringFromIndex:[OBJC_CLASS_RO length]];
        [_interfaceKeys addObject: symbolName];
        [_keyToProperName setObject:symbolName forKey:symbolName];
        return OBJC_SYMBOLS_SUCCESS;
    }
    
    else if ([symbol hasPrefix:(NSString*)OBJC_PROTOCOL]) {
        NSString *protocolName = [symbol substringFromIndex:[OBJC_PROTOCOL length]];
        if ([backlisted containsObject:protocolName]) {
            return OBJC_SYMBOLS_BLACKLIST_CLASS;
        }
        
        [_protocolKeys addObject: symbol];
        return OBJC_SYMBOLS_SUCCESS;
    }
    
    else if ([symbol hasPrefix:(NSString*)OBJC_CATEGORY]) {
        NSArray<NSString*> *splitCategory = [[symbol substringFromIndex: [OBJC_CATEGORY length]] componentsSeparatedByString:@"_$_"];
        NSString *key = [NSString stringWithFormat:@"%@(%@)", [splitCategory objectAtIndex:0], [splitCategory objectAtIndex:1]];
        NSString *value = [NSString stringWithFormat:@"%@ (%@)", [splitCategory objectAtIndex:0], [splitCategory objectAtIndex:1]];
        
        [_categoryKeys addObject: key];
        [_keyToProperName setObject:value forKey:key];
        return OBJC_SYMBOLS_SUCCESS;
    }
    
    //                } else if ([name hasPrefix:(NSString*)OBJC_PROP_LIST] || [name hasPrefix:(NSString*)OBJC_INSTANCE_VARIABLES]
    //                           || [name hasPrefix:(NSString*)OBJC_INSTANCE_METHODS] || [name hasPrefix:(NSString*)OBJC_CLASS_METHODS]
    //                           || [name hasPrefix:(NSString*)OBJC_METACLASS] || [name hasPrefix:(NSString*)OBJC_PROTOCOL_INSTANCE_METHODS]
    //                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_INSTANCE_METHODS_OPT] || [name hasPrefix:(NSString*)OBJC_PROTOCOL_METHOD_TYPES]
    //                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_REFS] || [name hasPrefix:(NSString*)OBJC_CLASS_PROTOCOLS]
    //                           || [name hasPrefix:(NSString*)OBJC_LABEL_PROTOCOL]
    //                           || [name hasPrefix:(NSString*)OBJC_CLASS_PROP_LIST]
    //                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_CLASS_METHODS] || [name hasPrefix:(NSString*)OBJC_METACLASS_RO]
    //                           || [name hasPrefix:(NSString*)OBJC_PROTOCOL_REFERENCE]) {
    //                    [_localIgnoreSymbols addObject:name];
    
    else if ([symbol hasPrefix:(NSString*)OBJC_ONE_UNDERSCORE_IDENTIFIER] || [symbol hasPrefix:(NSString*)OBJC_TWO_UNDERSCORES_IDENTIFIER]) {
        [_ignored addObject:symbol];
        return OBJC_SYMBOLS_IGNORED;
    }
    
    return OBJC_SYMBOLS_NOT_VALID;
}

-(void)sortResults {
    for (NSString *key in _methods) {
        [_methods[key] sortUsingSelector:@selector(compare:)];
    }
    
    for (NSString *key in _variables) {
        [_variables[key] sortUsingSelector:@selector(compare:)];
    }
}

@end
