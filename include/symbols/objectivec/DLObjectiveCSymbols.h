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

#import "DLObjectiveCMethod.h"
#import "DLObjectiveCIVar.h"

typedef enum ObjectiveCSymbolsResults {
    OBJC_SYMBOLS_BLACKLIST_CLASS,
    OBJC_SYMBOLS_IGNORED,
    OBJC_SYMBOLS_NOT_VALID,
    OBJC_SYMBOLS_SUCCESS
} ObjectiveCSymbolsResults;

typedef enum ObjectiveCType {
    OBJC_TYPE_CATEGORY,
    OBJC_TYPE_INTERFACE,
    OBJC_TYPE_PROTOCOL
} ObjectiveCType;

NS_ASSUME_NONNULL_BEGIN

@interface DLObjectiveCSymbols : NSObject

@property(readonly) NSMutableDictionary<NSString*,NSString*> *filenames;

@property(readonly) NSMutableSet<NSString*> *categoryKeys;
@property(readonly) NSMutableSet<NSString*> *interfaceKeys;
@property(readonly) NSMutableSet<NSString*> *protocolKeys;

@property(readonly) NSMutableDictionary<NSString*,NSMutableArray<DLObjectiveCMethod*>*> *methods;
@property(readonly) NSMutableDictionary<NSString*,NSMutableArray<DLObjectiveCIVar*>*> *variables;
@property(readonly) NSMutableDictionary<NSString*,NSString*> *keyToProperName;

@property(readonly) NSMutableArray<NSString*> *ignored;

-(ObjectiveCSymbolsResults)addObjectiveCSymbol:(NSString*)symbol;
-(void)sortResults;

@end

NS_ASSUME_NONNULL_END
