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

#import "DLStubBuilder.h"
#import "DLObjCStubBuilder.h"

const NSString *defaultCopyRight = @"/*\n\
 This file is part of Darling.\n\
\n\
 Copyright (C) %@ Darling Team\n\
\n\
 Darling is free software: you can redistribute it and/or modify\n\
 it under the terms of the GNU General Public License as published by\n\
 the Free Software Foundation, either version 3 of the License, or\n\
 (at your option) any later version.\n\
\n\
 Darling is distributed in the hope that it will be useful,\n\
 but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
 GNU General Public License for more details.\n\
\n\
 You should have received a copy of the GNU General Public License\n\
 along with Darling.  If not, see <http://www.gnu.org/licenses/>.\n\
*/";

const NSString *defaultCFuncStub = @"\
void* %s(void)\n\
{\n\
    if (verbose) puts(\"STUB: %s called\");\n\
    return NULL;\n\
}\n\
";



@implementation DLStubBuilder {
    NSMutableArray<NSString*> *_mainIncludeHeader;
    NSMutableArray<NSString*> *_sourceFileList;
}

-(instancetype) initWithArguments:(DLArgumentParser*)argumentParser
                       andSymbols:(DLLibraryParser*)libraryParser {
    _arguments = argumentParser;
    _libraryParser = libraryParser;
    
    _mainIncludeHeader = nil;
    _copyrightHeader = (NSString *)defaultCopyRight;
    _cFuncStub = (NSString *)defaultCFuncStub;
    return self;
}

-(void)setUpPathsIn:(NSURL*)outputFolder forLibrary:(NSString*)libraryName {
    NSFileManager *defaultFileManager = NSFileManager.defaultManager;
    
    _rootFolder = [outputFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@/", libraryName]];
    _srcFolder = [_rootFolder URLByAppendingPathComponent: @"src/"];
    _includeFolder = [_rootFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"include/%@/", libraryName]];
    
    [defaultFileManager createDirectoryAtURL:_rootFolder withIntermediateDirectories:YES attributes:nil error:nil];
    [defaultFileManager createDirectoryAtURL:_srcFolder withIntermediateDirectories:YES attributes:nil error:nil];
    [defaultFileManager createDirectoryAtURL:_includeFolder withIntermediateDirectories:YES attributes:nil error:nil];
}

-(void) appendCopyRightHeaderTo:(NSMutableString*)mutableString {
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:@"yyyy"];
    
    [mutableString appendFormat:_copyrightHeader, [dateFormater stringFromDate: [NSDate date]]];
    [mutableString appendString:@"\n\n"];
}


-(void) generateFilesToOutputFolder {
    NSURL *outputFolder = _arguments.outputUrl;
    NSString *libraryName = _libraryParser.mainImage.imageName;
    _mainIncludeHeader = [[NSMutableArray alloc] init];
    _sourceFileList = [[NSMutableArray alloc] init];
    
    [self setUpPathsIn:outputFolder forLibrary:libraryName];
    DLObjCStubBuilder *objCStubBuilder = [[DLObjCStubBuilder alloc] initWithArguments:_arguments andObjcSymbols:_libraryParser.objCSymbols];
    
    for (NSString *interfaceName in _libraryParser.objCSymbols.interfaceKeys) {
        [self generateObjCHeaderFromKey:interfaceName
                          usingSymbols:objCStubBuilder
                            forLibrary:libraryName];
        [self generateObjCSourceFromKey:interfaceName
                           usingSymbols:objCStubBuilder
                             forLibrary:libraryName];
    }
    
    for (NSString *categoryName in _libraryParser.objCSymbols.categoryKeys) {
        [self generateObjCHeaderFromKey:categoryName
                          usingSymbols:objCStubBuilder
                            forLibrary:libraryName];
        [self generateObjCSourceFromKey:categoryName
                           usingSymbols:objCStubBuilder
                             forLibrary:libraryName];
    }
    
    for (NSString *protocolName in _libraryParser.objCSymbols.protocolKeys) {
        [self generateObjCHeaderFromKey:protocolName
                          usingSymbols:objCStubBuilder
                            forLibrary:libraryName];
    }
    
    [self generateMainHeaderFrom:_libraryParser usingIncludes:_mainIncludeHeader];
    [self generateMainSourceFrom:_libraryParser addSourceIfCreated:_sourceFileList];
    [self generateCMakeListsFrom:_libraryParser usingSources:_sourceFileList];
}

-(void) generateObjCHeaderFromKey:(NSString*)key
                    usingSymbols:(DLObjCStubBuilder*)objCStubBuilder
                       forLibrary:(NSString*)libraryName {
    NSString *fileName = _libraryParser.objCSymbols.filenames[key];
    assert(fileName != nil);
    
    // Add header to main header
    [_mainIncludeHeader addObject: [NSString stringWithFormat:@"#import <%@/%@.h>", libraryName, fileName]];
    
    // Generate the header file
    NSMutableString *includeFile = [[NSMutableString alloc] initWithString:@""];
    [self appendCopyRightHeaderTo:includeFile];
    [objCStubBuilder generateHeaderFor:key withResultsSavedTo:includeFile];
    
    // Save the generated header file on disk
    NSURL *includeFilePath = [_includeFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.h", fileName]];
    [includeFile writeToURL:includeFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
}

-(void) generateObjCSourceFromKey:(NSString*)key
                    usingSymbols:(DLObjCStubBuilder*)objCStubBuilder
                      forLibrary:(NSString*)libraryName {
    NSString *fileName = _libraryParser.objCSymbols.filenames[key];
    assert(fileName != nil);
    
    // Add source to cMake build list
    [_sourceFileList addObject: [NSString stringWithFormat:@"src/%@.m", fileName]];
    
    // Generate source file
    NSMutableString *sourceFile = [[NSMutableString alloc] initWithString:@""];
    [self appendCopyRightHeaderTo:sourceFile];
    [objCStubBuilder generateSourceFor:key toLibrary:libraryName withResultsSavedTo:sourceFile];
    
    // Save the generated source file on disk
    NSURL *sourceFilePath = [_srcFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.m", fileName]];
    [sourceFile writeToURL:sourceFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void) generateCMakeListsFrom:(DLLibraryParser*)libraryParser
                  usingSources:(NSMutableArray<NSString*>*)listOfSourceFiles {
    NSURL *cMakeListsPath = [_rootFolder URLByAppendingPathComponent: @"CMakeLists.txt"];
    NSMutableString *cMakeLists = [[NSMutableString alloc] init];
    NSString *libraryName = libraryParser.mainImage.imageName;
    DLMainImageFrameworkType frameworkType = libraryParser.mainImage.frameworkType;
    DLMainImageImageType imageType = libraryParser.mainImage.imageType;
    
    [cMakeLists appendFormat:@"project(%@)\n\n",libraryName];
    
    [cMakeLists appendFormat:@"remove_sdk_framework(%@", libraryName];
    if (frameworkType == FrameworkTypePrivate) { [cMakeLists appendString:@"\n\tPRIVATE\n"]; }
    [cMakeLists appendString:@")\n\n"];
    
    if (imageType == ImageTypeDylib) { [cMakeLists appendFormat:@"set(DYLIB_INSTALL_NAME \"%@\")\n",libraryParser.mainImage.imagePath]; }
    [cMakeLists appendFormat:@"set(DYLIB_COMPAT_VERSION \"%@\")\n",libraryParser.mainImage.compabilityVersion];
    [cMakeLists appendFormat:@"set(DYLIB_CURRENT_VERSION \"%@\")\n\n",libraryParser.mainImage.currentVersion];
    
    if (imageType == ImageTypeFramework) {
        [cMakeLists appendString:@"set(FRAMEWORK_VERSION \"A\")\n\n"];
        
        [cMakeLists appendFormat:@"generate_sdk_framework(%@\n", libraryName];
        if (frameworkType == FrameworkTypePrivate) { [cMakeLists appendString:@"\tPRIVATE\n"]; }
        [cMakeLists appendString:@"\tVERSION ${FRAMEWORK_VERSION}\n"];
        [cMakeLists appendFormat:@"\tHEADER \"include/%@\"\n", libraryName];
        [cMakeLists appendString:@")\n\n\n"];
        
        [cMakeLists appendFormat:@"add_framework(%@\n",libraryName];
        if (frameworkType == FrameworkTypePrivate) { [cMakeLists appendString:@"\tPRIVATE\n"]; }
        [cMakeLists appendString:@"\tFAT\n"];
        [cMakeLists appendString:@"\tCURRENT_VERSION\n"];
        [cMakeLists appendString:@"\tVERSION ${FRAMEWORK_VERSION}\n\n"];
        
        [cMakeLists appendString:@"\tSOURCES\n"];
        for (NSString *sourceFile in listOfSourceFiles) {
            [cMakeLists appendFormat:@"\t\t%@\n", sourceFile];
        }
        [cMakeLists appendString:@"\n"];
        
        [cMakeLists appendString:@"\tDEPENDENCIES\n"];
        [cMakeLists appendString:@"\t\tsystem\n"];
        [cMakeLists appendString:@"\t\tobjc\n"];
        [cMakeLists appendString:@"\t\tFoundation\n"];
        
        [cMakeLists appendString:@")"];
    } else if (imageType == ImageTypeDylib) {
        /*
         
         if library:
             cmake.write("add_darling_library(%s SHARED\n" % target_name)
             cmake.write("    src/%s." % target_name + ("m" if uses_objc else "c") + "\n")
             if uses_objc:
                 write_objc_source_file_locs(cmake, classes, 4)
             cmake.write(")\n")
             cmake.write("make_fat(%s)\n" % target_name)
             libraries = "system objc Foundation" if uses_objc else "system"
             cmake.write("target_link_libraries(%s %s)\n" % (target_name, libraries))
             cmake.write("install(TARGETS %s DESTINATION libexec/darling/usr/lib)\n" % target_name)
         
         */
        
        [cMakeLists appendFormat:@"add_darling_library(%@ SHARED\n",libraryName];
        
        for (NSString *sourceFile in listOfSourceFiles) {
            [cMakeLists appendFormat:@"\t%@\n", sourceFile];
        }
        [cMakeLists appendString:@")\n\n"];
        
        [cMakeLists appendFormat:@"make_fat(%@)\n",libraryName];
        [cMakeLists appendFormat:@"target_link_libraries(%@ %@)\n",libraryName,@"system"];
        [cMakeLists appendFormat:@"install(TARGETS %@ DESTINATION %@)\n", libraryName, @"libexec/darling/usr/lib"];
    }
    
    [cMakeLists writeToURL:cMakeListsPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void) generateMainSourceFrom:(DLLibraryParser*)libraryParser
                  addSourceIfCreated:(NSMutableArray<NSString*>*)listOfSourceFiles {
    bool thereAreCVariables = [_libraryParser.cSymbols.variables count] > 0;
    bool thereAreCFunctions = [_libraryParser.cSymbols.functions count] > 0;
    
    // Only create the file if there are any C variables/functions.
    if (thereAreCVariables || thereAreCFunctions) {
        NSString *libraryName = libraryParser.mainImage.imageName;
        
        NSMutableString *mainSource = [[NSMutableString alloc] init];
        NSString *fileName = [NSString stringWithFormat:@"%@.m", libraryName];
        NSURL *mainSourcePath = [_srcFolder URLByAppendingPathComponent: fileName];
        
        [self appendCopyRightHeaderTo: mainSource];
        [mainSource appendString:@"\n"];
        
        [mainSource appendFormat:@"#include <%@/%@.h>\n", libraryName, libraryName];
        [mainSource appendString:@"#include <stdlib.h>\n"];
        [mainSource appendString:@"#include <stdio.h>\n\n"];
        
        [mainSource appendString:@"__attribute__((constructor))\n"];
        [mainSource appendString:@"static void initme(void) {\n"];
        [mainSource appendString:@"    verbose = getenv(\"STUB_VERBOSE\") != NULL;\n"];
        [mainSource appendString:@"}\n\n"];
        
        if (thereAreCVariables) {
            [mainSource appendString:@"\n"];
            for (DLCVariable* cVariable in _libraryParser.cSymbols.variables) {
                NSString *cVariableString = [cVariable generateStubVariableSource];
                if (cVariableString != nil) {
                    [mainSource appendFormat:@"%@;\n", cVariableString];
                }
            }
        }
        
        if (thereAreCFunctions) {
            [mainSource appendString:@"\n"];
            for (DLCFunction* cFunction in _libraryParser.cSymbols.functions) {
                [mainSource appendFormat:@"%@ {\n", [cFunction generateStubMethod]];
                [mainSource appendFormat:@"    if (verbose) puts(\"STUB: %@ called\");\n", cFunction.functionName];
                [mainSource appendString:@"    return NULL;\n"];
                [mainSource appendString:@")\n\n"];
            }
        }
        
        [listOfSourceFiles addObject:[NSString stringWithFormat:@"src/%@", fileName]];
        [mainSource writeToURL:mainSourcePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

-(void) generateMainHeaderFrom:(DLLibraryParser*)libraryParser
                 usingIncludes:(NSMutableArray<NSString*>*)mainHeaderIncludes {
    NSString *libraryName = libraryParser.mainImage.imageName;
    NSString *upperLibraryName = libraryName.uppercaseString;
    
    NSMutableString *mainInclude = [[NSMutableString alloc] init];
    NSURL *mainIncludePath = [_includeFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.h", libraryName]];
    
    [self appendCopyRightHeaderTo: mainInclude];
    [mainInclude appendFormat:@"#ifndef _%@_H_\n#define _%@_H_\n\n#import <Foundation/Foundation.h>", upperLibraryName, upperLibraryName];
    
    if ([mainHeaderIncludes count] > 0) {
        [mainInclude appendString:@"\n\n"];
        [mainHeaderIncludes sortUsingSelector:@selector(compare:)];
        for (NSString *headerInclude in mainHeaderIncludes) {
            [mainInclude appendFormat:@"%@\n", headerInclude];
        }
    }
    
    if ([_libraryParser.cSymbols.functions count] > 0) {
        [mainInclude appendString:@"\n\n"];
        for (DLCFunction* cFunction in _libraryParser.cSymbols.functions) {
            [mainInclude appendFormat:@"%@;\n", [cFunction generateStubMethod]];
        }
    }
    
    if ([_libraryParser.cSymbols.variables count] > 0) {
        [mainInclude appendString:@"\n\n"];
        for (DLCVariable* cVariable in _libraryParser.cSymbols.variables) {
            NSString *cVariableString = [cVariable generateStubVariableHeader];
            if (cVariableString != nil) {
                [mainInclude appendFormat:@"%@;\n", cVariableString];
            }
        }
    }

    
    [mainInclude appendString:@"\n#endif\n\n"];
    [mainInclude writeToURL:mainIncludePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
