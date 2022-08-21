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

#import "DLLogResults.h"

@implementation DLLogResults

-(instancetype)initWithArguments:(DLArgumentParser*)arugmentParser {
    _arugments = arugmentParser;
    return self;
}

-(void)logResultsFromParsedLibrary:(DLLibraryParser*)libraryParser toFolder:(NSURL*)rootFolder {
    if (_arugments.logSymbols) {
        NSFileManager *defaultFileManager = NSFileManager.defaultManager;
        
        NSURL *logPath = [rootFolder URLByAppendingPathComponent: @"log/"];
        [defaultFileManager createDirectoryAtURL:logPath
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:nil];
        
        NSMutableString *localIgnoreSymbolsFile = [[NSMutableString alloc] init];
        [self logListOfStrings:libraryParser.localIgnoreSymbols toString:localIgnoreSymbolsFile];
        [localIgnoreSymbolsFile writeToURL:[logPath URLByAppendingPathComponent:@"local_ignored_symbols.txt"]
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
        
        NSMutableString *localUnknownSymbolsFile = [[NSMutableString alloc] init];
        [self logListOfStrings:libraryParser.localUnknownSymbols toString:localUnknownSymbolsFile];
        [localUnknownSymbolsFile writeToURL:[logPath URLByAppendingPathComponent:@"local_unknown_symbols.txt"]
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
        
        NSMutableString *externalSymbolsFile = [[NSMutableString alloc] init];
        [self logListOfStrings:libraryParser.externalSymbols toString:externalSymbolsFile];
        [externalSymbolsFile writeToURL:[logPath URLByAppendingPathComponent:@"external_symbols.txt"]
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
        
        NSMutableString *undefinedSymbolsFile = [[NSMutableString alloc] init];
        [self logListOfStrings:libraryParser.undefinedSymbols toString:undefinedSymbolsFile];
        [undefinedSymbolsFile writeToURL:[logPath URLByAppendingPathComponent:@"undefinied_symbols.txt"]
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
    }
}

-(void) logListOfStrings:(NSMutableArray<NSString*>*)listOfString toString:(NSMutableString*)mutSymbols {
    for (NSString *string in listOfString) {
        [mutSymbols appendString:string];
        [mutSymbols appendString:@"\n"];
    }
}

@end
