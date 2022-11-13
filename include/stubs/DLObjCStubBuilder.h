//
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
#import "DLArgumentParser.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSString *OBJ_C_IMPLEMENTATION;
extern const NSString *OBJ_C_IMPLEMENTATION_CATEGORY;
extern const NSString *OBJ_C_PROTOCAL;
extern const NSString *OBJ_C_INTERFACE_CLASSNAME;
extern const NSString *OBJ_C_INTERFACE_CATEGORY;
extern const NSString *OBJ_C_END;

@interface DLObjCStubBuilder : NSObject {
    DLArgumentParser *_arguments;
}

-(instancetype)initWithArguments:(DLArgumentParser*)arguments
                  andObjcSymbols:(DLObjectiveCSymbols*)objCSymbols;

-(void) generateHeaderFor:(NSString*)key
              andObjCType:(NSString*)objCType
       withResultsSavedTo:(NSMutableString*)mutableHeaderString;
-(void) generateSourceFor:(NSString*)key
                toLibrary:(NSString*)libraryName
              andObjCType:(NSString*)objCType
       withResultsSavedTo:(NSMutableString*)mutableHeaderString;

@property(readonly) DLObjectiveCSymbols *objCSymbols;

@end

NS_ASSUME_NONNULL_END
