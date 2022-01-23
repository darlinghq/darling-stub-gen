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

#import "DLObjectiveCMethod.h"

@implementation DLObjectiveCMethod

-(instancetype)init {
    _className = nil;
    _methodType = nil;
    _methodParts = [[NSMutableArray alloc] init];
    return self;
}

-(NSString*)description {
    NSMutableString *temp = [[NSMutableString alloc] init];
    
    [temp appendString:_methodType]; [temp appendString:@"["]; [temp appendString:_className];
    
    [temp appendString:@" "];
    for (NSString *currentSelector in _methodParts) {
        [temp appendString:currentSelector];
    }
    
    [temp appendString:@"]"];
    
    return temp;
}

-(NSString*)generateStubMethod {
    NSMutableString *temp = [[NSMutableString alloc] init];
    NSUInteger index = 1;
    
    [temp appendFormat:@"%@(%@)", _methodType, @"id"];
    for (NSString *methodPart in _methodParts) {
        if ([methodPart hasSuffix:@":"]) {
            [temp appendFormat:@"%@(%@)%@ ", methodPart, @"id", [NSString stringWithFormat:@"arg%lu", (unsigned long)index]];
        } else {
            [temp appendFormat:@"%@ ", methodPart];
        }
        
        index++;
    }
    
    if ([temp hasSuffix:@" "]) {
        [temp deleteCharactersInRange:NSMakeRange(temp.length-1, 1)];
    }
    
    return temp;
}

-(NSComparisonResult)compare: (DLObjectiveCMethod*)otherMethod {
    NSString *left = self.description;
    NSString *right = otherMethod.description;
    
    return [left compare:right];
}

-(void)createMethod:(NSString *)method {
    // Remove '+[' / '-[' and ']' from the Objective C methods
    // +[MTLIOAccelDevice registerDevices]
    NSArray<NSString*> *splitMethod = [[[method substringToIndex:method.length-1] substringFromIndex:2] componentsSeparatedByString:@" "];
    NSString *selector = [splitMethod objectAtIndex:1];
    
    _className = [splitMethod objectAtIndex:0];
    _methodType = [method substringToIndex:1];
    
    
    const char *utf8Selctor = [selector UTF8String];
    NSMutableString *selectorSection = [[NSMutableString alloc] init];
    for (NSUInteger i=0; i < selector.length; i++) {
        char item = utf8Selctor[i];
        [selectorSection appendString: [NSString stringWithFormat:@"%c", item]];
        if (item == ':') {
            [_methodParts addObject:selectorSection];
            selectorSection = [[NSMutableString alloc] init];
        }
    }
    
    if (![selectorSection isEqualToString:@""]) {
        [_methodParts addObject:selectorSection];
    }
}

+(instancetype)parseMethod: (NSString *)method {
    DLObjectiveCMethod *parsedMethod = [[DLObjectiveCMethod alloc] init];
    [parsedMethod createMethod:method];
    
    return parsedMethod;
}

@end
