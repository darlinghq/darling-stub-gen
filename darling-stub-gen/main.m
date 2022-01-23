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
#import <MachOKit/MachOKit.h>

#import "DLArgumentParser.h"
#import "DLLibraryParser.h"
#import "DLStubBuilder.h"
#import "DLLogResults.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        DLArgumentParser *argumentParser = [DLArgumentParser parseArguments:argv forSize:argc];
        
        NSError *error;
        MKMemoryMap *memoryMap = [MKMemoryMap memoryMapWithContentsOfFile: argumentParser.inputUrl error: &error];
        
//        MKFatBinary *fatBinary = [[MKFatBinary alloc] initWithMemoryMap: memoryMap error: &error];
//        if (fatBinary != nil) {
//            //
//        }
        
        MKMachOImage *machImage = [[MKMachOImage alloc] initWithName:nil flags:0 atAddress:0 inMapping:memoryMap error:&error];
        
        DLLibraryParser *libraryParser = [[DLLibraryParser alloc] init];
        [libraryParser parseDependentLibraryWithMachOImage:machImage];
        [libraryParser parseSymbolWithMachOImage:machImage];
        [libraryParser parseCurrentMachOImage:machImage];
        
        DLStubBuilder *stubBuilder = [[DLStubBuilder alloc] initWithArguments:argumentParser];
        [stubBuilder generateFilesToOutputFolder: argumentParser.outputUrl usingStubParser:libraryParser];
        
        DLLogResults *logResults = [[DLLogResults alloc] initWithArguments:argumentParser];
        [logResults logResultsFromParsedLibrary:libraryParser toFolder:stubBuilder.rootFolder];
    }
    
    return 0;
}
