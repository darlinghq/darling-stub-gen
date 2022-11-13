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

#import "DLObjCStubBuilder.h"

const NSString *defaultObjCMethodStub = @"\
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector\n\
{\n\
    return [NSMethodSignature signatureWithObjCTypes: \"v@:\"];\n\
}\n\n\
- (void)forwardInvocation:(NSInvocation *)anInvocation\n\
{\n\
    NSLog(@\"Stub called: %@ in %@\", NSStringFromSelector([anInvocation selector]), [self class]);\n\
}\n\
\n\
";

const NSString *OBJ_C_IMPLEMENTATION = @"@implementation %@\n";
const NSString *OBJ_C_PROTOCAL = @"@protocol %@";
const NSString *OBJ_C_INTERFACE = @"@interface %@";
const NSString *OBJ_C_INTERFACE_EXTENDS_NSOBJECT = @"@interface %@ : NSObject";
const NSString *OBJ_C_END = @"@end\n";

@implementation DLObjCStubBuilder

-(instancetype)initWithArguments:(DLArgumentParser*)arguments
                  andObjcSymbols:(DLObjectiveCSymbols*)objCSymbols{
    _arguments = arguments;
    _objCSymbols = objCSymbols;
    return self;
}

-(void) generateHeaderFor:(NSString*)key
       withResultsSavedTo:(NSMutableString*)mutableHeaderString {
    NSArray<DLObjectiveCMethod*> *listOfMethods = _objCSymbols.methods[key];
    NSMutableArray<DLObjectiveCIVar*> *listOfVariables = _objCSymbols.variables[key];
    DLObjectiveCType objCType = [_objCSymbols.type[key] unsignedIntegerValue];
    
    NSString *objCString = nil;
    if (objCType == OBJC_TYPE_CLASS) {
        objCString = (NSString*)OBJ_C_INTERFACE_EXTENDS_NSOBJECT;
    } else if (objCType == OBJC_TYPE_CATEGORY) {
        objCString = (NSString*)OBJ_C_INTERFACE;
    } else if (objCType == OBJC_TYPE_PROTOCOL) {
        objCString = (NSString*)OBJ_C_PROTOCAL;
    } else {
        NSLog(@"Unknown objCType");
        return;
    }
    
    
    [mutableHeaderString appendString:@"#include <Foundation/Foundation.h>\n"];
    [mutableHeaderString appendString:@"\n"];
    
    [mutableHeaderString appendFormat:objCString, _objCSymbols.properName[key]];
    
    if (objCType == OBJC_TYPE_CLASS) {
        if (!_arguments.useMethodSignature) {
            if (listOfMethods.count > 0) {
                [mutableHeaderString appendString:@" {\n"];
                for (DLObjectiveCIVar *objCVar in listOfVariables) {
                    [mutableHeaderString appendFormat:@"\t%@;\n", [objCVar generateStubVariable]];
                }
                [mutableHeaderString appendString:@"}\n"];
            } else {
                [mutableHeaderString appendString:@"\n"];
            }
            [mutableHeaderString appendString:@"\n"];
            
            for (DLObjectiveCMethod *objCMethod in listOfMethods) {
                [mutableHeaderString appendString:[objCMethod generateStubMethod]];
                [mutableHeaderString appendString:@";\n"];
            }
        } else {
            [mutableHeaderString appendString:@"\n"];
        }
    }
    
    else if (objCType == OBJC_TYPE_CATEGORY) {
        [mutableHeaderString appendString:@"\n"];
    }
    
    else if (objCType == OBJC_TYPE_PROTOCOL) {
        [mutableHeaderString appendString:@"\n"];
    }
    
    [mutableHeaderString appendString:@"\n"];
    [mutableHeaderString appendString:(NSString*)OBJ_C_END];
}

-(void) generateSourceFor:(NSString*)key
                toLibrary:(NSString*)libraryName
       withResultsSavedTo:(NSMutableString*)mutableHeaderString
{
    NSArray<DLObjectiveCMethod*> *listOfMethods = _objCSymbols.methods[key];
    DLObjectiveCType objCType = [_objCSymbols.type[key] unsignedIntegerValue];
    
    NSString *objCString = nil;
    if (objCType == OBJC_TYPE_CLASS) {
        objCString = (NSString*)OBJ_C_IMPLEMENTATION;
    } else if (objCType == OBJC_TYPE_CATEGORY) {
        objCString = (NSString*)OBJ_C_IMPLEMENTATION;
    } else {
        NSLog(@"Unknown objCType");
        return;
    }
    
    
    [mutableHeaderString appendFormat:@"#import <%@/%@.h>\n", libraryName, _objCSymbols.filenames[key]];
    [mutableHeaderString appendString:@"\n"];
    
    [mutableHeaderString appendFormat:objCString, _objCSymbols.properName[key]];
    [mutableHeaderString appendString:@"\n"];
    
    if (objCString == OBJ_C_IMPLEMENTATION) {
        if (_arguments.useMethodSignature && objCType != OBJC_TYPE_CATEGORY) {
            [mutableHeaderString appendString:(NSString*)defaultObjCMethodStub];
        } else if (!_arguments.useMethodSignature && listOfMethods.count > 0) {
            for (DLObjectiveCMethod *objCMethod in listOfMethods) {
                [mutableHeaderString appendFormat:@"%@ {\n\t%@\n}\n\n", [objCMethod generateStubMethod], @"NSLog(@\"%@\", NSStringFromSelector(_cmd));"];
            }
        }
    }
    
    [mutableHeaderString appendString:(NSString*)OBJ_C_END];
}

@end
