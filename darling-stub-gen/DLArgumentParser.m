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

#import "DLArgumentParser.h"

@implementation DLArgumentParser

-(instancetype)initWithArguments:(const char *_Nonnull*)argv forSize:(int)argc {
    _inputFile = [NSString stringWithUTF8String:argv[1]];
    _outputPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
    
    _logSymbols = true;
    _useMethodSignature = true;
    return self;
}

+(instancetype)parseArguments:(const char *_Nonnull*)argv forSize:(int)argc {
    DLArgumentParser *argumentParser = [[DLArgumentParser alloc] initWithArguments:argv forSize:argc];
    return argumentParser;
}

-(NSURL*) inputUrl {
    return [NSURL fileURLWithPath: _inputFile];
}

-(NSURL*) outputUrl {
    return [NSURL fileURLWithPath: _outputPath];
}

@end
