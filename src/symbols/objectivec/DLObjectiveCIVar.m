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

#import "DLObjectiveCIVar.h"

const NSString *I_VAR_STRING_PREFIX = @"_OBJC_IVAR_$_";

@implementation DLObjectiveCIVar

-(NSComparisonResult)compare: (DLObjectiveCIVar*)otherVariable {
    NSString *left = self.description;
    NSString *right = otherVariable.description;
    
    return [left compare:right];
}

-(NSString*)description {
    NSMutableString *temp = [[NSMutableString alloc] init];
    [temp appendString:(NSString*)I_VAR_STRING_PREFIX];
    [temp appendString:_className];
    [temp appendString:@"."];
    [temp appendString:_variableName];
    
    return temp;
}

-(NSString*) generateStubVariable {
    return [NSString stringWithFormat:@"id %@", _variableName];
}

-(instancetype)initUsingVariable:(NSString *)variable {
    // _OBJC_IVAR_$__MTLIOAccelMTLEvent._device
    NSUInteger iVarStringLength = [I_VAR_STRING_PREFIX length];
    NSString *temp = [variable substringFromIndex:iVarStringLength];
    NSArray<NSString *> *splitTemp = [temp componentsSeparatedByString:@"."];
    
    _className = [splitTemp objectAtIndex:0];
    _variableName = [splitTemp objectAtIndex:1];
    
    return self;
}

+(instancetype)parseVariable: (NSString *)variable {
    DLObjectiveCIVar *parsedVariable = [[DLObjectiveCIVar alloc] initUsingVariable:variable];
    return parsedVariable;
}

@end
