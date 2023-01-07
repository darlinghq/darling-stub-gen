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

#import "DLCVariable.h"

@implementation DLCVariable {
    BOOL _constant;
    BOOL _static;
    NSString *_name;
}

+(instancetype)parseVariable:(NSString *)variableName
                  isConstant:(BOOL)isConstant
                    isStatic:(BOOL)isStatic {
    return [[DLCVariable alloc] initWithVariableName:variableName
                                          isConstant:isConstant
                                            isStatic:isStatic];
}

-(instancetype)initWithVariableName:(NSString*)variableName
                         isConstant:(BOOL)isConstant
                           isStatic:(BOOL)isStatic {
    if ([variableName hasPrefix:@"_"]) { variableName = [variableName substringFromIndex:1]; }
    _constant = isConstant;
    _name = variableName;
    _static = isStatic;
    return self;
}

-(NSString*)generateStubVariable {
    NSMutableString *genVariable = [[NSMutableString alloc] initWithString:@"extern "];
    if (_static) {
        [genVariable appendString:@"static "];
    }
    
    if (_constant) {
        [genVariable appendString:@"const "];
    }
    
    [genVariable appendFormat:@"void* %@", _name];
    return genVariable;
}

-(NSString*)generateStubVariableSource {
    return [[self generateStubVariable] stringByAppendingString:@" = (void*)0"];
}

-(NSString*)generateStubVariableHeader {
    if (_static) {
        return nil;
    }
    
    return [NSString stringWithFormat:@"extern %@", [self generateStubVariable]];
}

@end
