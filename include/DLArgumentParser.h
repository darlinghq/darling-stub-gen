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

NS_ASSUME_NONNULL_BEGIN

@interface DLArgumentParser : NSObject

@property(readonly) NSString* inputFile;
@property(readonly) NSString* outputPath;
@property(readonly) bool logSymbols;
@property(readonly) bool useMethodSignature;

+(instancetype)parseArguments:(const char *_Nonnull*_Nonnull)argv forSize:(int)argc;

-(NSURL*) inputUrl;
-(NSURL*) outputUrl;

@end

NS_ASSUME_NONNULL_END
