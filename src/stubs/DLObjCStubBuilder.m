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
const NSString *OBJ_C_IMPLEMENTATION_CATEGORY = @"@implementation %@\n";
const NSString *OBJ_C_PROTOCAL = @"@protocol %@";
const NSString *OBJ_C_INTERFACE_CLASSNAME = @"@interface %@ : NSObject";
const NSString *OBJ_C_INTERFACE_CATEGORY = @"@interface %@";
const NSString *OBJ_C_END = @"@end\n";

@implementation DLObjCStubBuilder

-(instancetype)initWithArguments:(DLArgumentParser*)arguments
                  andObjcSymbols:(DLObjectiveCSymbols*)objCSymbols{
    _arguments = arguments;
    _objCSymbols = objCSymbols;
    return self;
}

-(void) generateHeaderFor:(NSString*)key
              andObjCType:(NSString*)objCType
       withResultsSavedTo:(NSMutableString*)mutableHeaderString {

    
    [mutableHeaderString appendString:@"#include <Foundation/Foundation.h>\n"];
    [mutableHeaderString appendString:@"\n"];
    
    [mutableHeaderString appendFormat:objCType, _objCSymbols.keyToProperName[key]];
    
    
    NSArray<DLObjectiveCMethod*> *listOfMethods = _objCSymbols.methods[key];
    NSMutableArray<DLObjectiveCIVar*> *listOfVariables = _objCSymbols.variables[key];
    
    if ([OBJ_C_INTERFACE_CLASSNAME isEqualToString:objCType]) {
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
    
    else if ([OBJ_C_IMPLEMENTATION_CATEGORY isEqualToString:objCType]) {
        
    }
    
    else if ([OBJ_C_PROTOCAL isEqualToString:objCType]) {
        [mutableHeaderString appendString:@"\n"];
    }
    
    [mutableHeaderString appendString:@"\n"];
    [mutableHeaderString appendString:(NSString*)OBJ_C_END];
}

-(void) generateSourceFor:(NSString*)key
                toLibrary:(NSString*)libraryName
              andObjCType:(NSString*)objCType
       withResultsSavedTo:(NSMutableString*)mutableHeaderString
{
    NSArray<DLObjectiveCMethod*> *listOfMethods = _objCSymbols.methods[key];
    
//    [mutableHeaderString appendString:@"#include <Foundation/Foundation.h>\n"];
    [mutableHeaderString appendFormat:@"#import <%@/%@.h>\n", libraryName, _objCSymbols.keyToProperName[key]];
    [mutableHeaderString appendString:@"\n"];
    
    [mutableHeaderString appendFormat:objCType, _objCSymbols.keyToProperName[key]];
    [mutableHeaderString appendString:@"\n"];
    
    if ([OBJ_C_IMPLEMENTATION isEqualToString:objCType]) {
        if (_arguments.useMethodSignature) {
            [mutableHeaderString appendString:(NSString*)defaultObjCMethodStub];
        } else if (listOfMethods.count > 0) {
            for (DLObjectiveCMethod *objCMethod in listOfMethods) {
                [mutableHeaderString appendFormat:@"%@ {\n\t%@\n}\n\n", [objCMethod generateStubMethod], @"NSLog(@\"%@\", NSStringFromSelector(_cmd));"];
            }
        }
    }
    
    [mutableHeaderString appendString:(NSString*)OBJ_C_END];
}

@end
