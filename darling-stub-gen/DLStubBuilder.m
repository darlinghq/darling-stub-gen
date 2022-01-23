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

const NSString *defaultCopyRight = @"/*\
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

const NSString *defaultObjCMethodStub = @"\
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector\n\
{\n\
    return [NSMethodSignature signatureWithObjCTypes: \"v@:\"];\n\
}\n\
- (void)forwardInvocation:(NSInvocation *)anInvocation\n\
{\n\
    NSLog(@\"Stub called: %@ in %@\", NSStringFromSelector([anInvocation selector]), [self class]);\n\
}\n\
\n\
";

const NSString *OBJ_C_IMPLEMENTATION = @"@implementation %@\n";
const NSString *OBJ_C_INTERFACE = @"@interface %@ : NSObject";
const NSString *OBJ_C_END = @"@end\n";

@implementation DLStubBuilder

-(instancetype) initWithArguments:(DLArgumentParser*)argumentParser {
    _arguments = argumentParser;
    
    _copyrightHeader = (NSString *)defaultCopyRight;
    _cFuncStub = (NSString *)defaultCFuncStub;
    _objCMethodStub = (NSString *)defaultObjCMethodStub;
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

-(void) generateFilesToOutputFolder:(NSURL*)outputFolder usingStubParser:(DLLibraryParser *)libraryParser {
    NSString *libraryName = libraryParser.mainImage.imageName;
    [self setUpPathsIn:outputFolder forLibrary:libraryName];
    
    NSMutableArray<NSString*> *mainHeaderIncludes = [[NSMutableArray alloc] init];
    NSMutableArray<NSString*> *listOfSourceFiles = [[NSMutableArray alloc] init];
    for (NSString *classname in libraryParser.classnameObjC) {
        NSMutableArray<DLObjectiveCIVar*>* listOfVariables = [libraryParser.variableObjC[classname] copy];
        NSMutableArray<DLObjectiveCMethod*>* listOfMethods = [libraryParser.methodsObjC[classname] copy];
        
        NSURL *sourceFilePath = [_srcFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.m", classname]];
        NSURL *includeFilePath = [_includeFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.h", classname]];
        NSMutableString *sourceFile = [[NSMutableString alloc] initWithString:@""];
        NSMutableString *includeFile = [[NSMutableString alloc] initWithString:@""];
        
        [self appendCopyRightHeaderTo:sourceFile];
        
        [mainHeaderIncludes addObject: [NSString stringWithFormat:@"#import <%@/%@.h>\n", libraryName, classname]];
        [self generateHeaderFor:classname
                   usingMethods:listOfMethods
                   andVariables:listOfVariables
             withResultsSavedTo:includeFile];
        
        [listOfSourceFiles addObject: [NSString stringWithFormat:@"src/%@.m", classname]];
        
        [sourceFile writeToURL:sourceFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [includeFile writeToURL:includeFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    [self generateCMakeListsFrom:libraryParser usingSources:listOfSourceFiles];
    [self generateMainHeaderFrom:libraryParser usingIncludes:mainHeaderIncludes];
}

-(void) generateCMakeListsFrom:(DLLibraryParser*)libraryParser
                 usingSources:(NSMutableArray<NSString*>*)listOfSourceFiles {
    NSURL *cMakeListsPath = [_rootFolder URLByAppendingPathComponent: @"CMakeLists.txt"];
    NSMutableString *cMakeLists = [[NSMutableString alloc] init];
    NSString *libraryName = libraryParser.mainImage.imageName;
    DLMainImageImageType imageType = libraryParser.mainImage.imageType;
    
    [cMakeLists appendFormat:@"project(%@)\n\n",libraryName];
    
    if (imageType == ImageTypeDylib) { [cMakeLists appendFormat:@"set(DYLIB_INSTALL_NAME \"%@\")\n",libraryParser.mainImage.imagePath]; }
    [cMakeLists appendFormat:@"set(DYLIB_COMPAT_VERSION \"%@\")\n",libraryParser.mainImage.compabilityVersion];
    [cMakeLists appendFormat:@"set(DYLIB_CURRENT_VERSION \"%@\")\n\n",libraryParser.mainImage.currentVersion];
    
    
    if (imageType == ImageTypeFramework) {
            [cMakeLists appendFormat:@"add_framework(%@\n",libraryName];
            [cMakeLists appendString:@"\tFAT\n"];
            [cMakeLists appendString:@"\tCURRENT_VERSION\n"];
            [cMakeLists appendString:@"\tVERSION \"A\"\n\n"];
            
            [cMakeLists appendString:@"\tSOURCES\n"];
            for (NSString *sourceFile in listOfSourceFiles) {
                [cMakeLists appendFormat:@"\t\t%@\n", sourceFile];
            }
            [cMakeLists appendString:@"\n\n"];
            
            [cMakeLists appendString:@"\tDEPENDENCIES\n"];
            [cMakeLists appendString:@"\t\tsystem\n"];
            [cMakeLists appendString:@"\t\tobjc\n"];
            [cMakeLists appendString:@"\t\tFoundation\n"];
            
            [cMakeLists appendString:@"}"];
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
        [cMakeLists appendString:@")\n"];
        
        [cMakeLists appendFormat:@"make_fat(%@)\n",libraryName];
        [cMakeLists appendFormat:@"target_link_libraries(%@ %@)\n",libraryName,@"system"];
        [cMakeLists appendFormat:@"install(TARGETS %@ DESTINATION %@)\n", libraryName, @"libexec/darling/usr/lib"];
    }
    
    [cMakeLists writeToURL:cMakeListsPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void) generateMainHeaderFrom:(DLLibraryParser*)libraryParser
                usingIncludes:(NSMutableArray<NSString*>*)mainHeaderIncludes {
    NSString *libraryName = libraryParser.mainImage.imageName;
    NSString *upperLibraryName = libraryName.uppercaseString;
    
    NSMutableString *mainInclude = [[NSMutableString alloc] init];
    NSURL *mainIncludePath = [_includeFolder URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.h", libraryName]];
    
    [self appendCopyRightHeaderTo: mainInclude];
    [mainInclude appendFormat:@"#ifndef _%@_H_\n#define _%@_H_\n\n#import <Foundation/Foundation.h>\n\n", upperLibraryName, upperLibraryName];
    
    [mainHeaderIncludes sortUsingSelector:@selector(compare:)];
    for (NSString *headerInclude in mainHeaderIncludes) {
        [mainInclude appendString:headerInclude];
    }
    
    [mainInclude appendString:@"\n#endif\n\n"];
    [mainInclude writeToURL:mainIncludePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void) generateHeaderFor:(NSString*)classname
             usingMethods:(NSMutableArray<DLObjectiveCMethod*>*)listOfMethods
             andVariables:(NSMutableArray<DLObjectiveCIVar*>*)listOfVariables
       withResultsSavedTo:(NSMutableString*)mutableHeaderString {
    [self appendCopyRightHeaderTo:mutableHeaderString];
    
    [mutableHeaderString appendString:@"#include <Foundation/Foundation.h>\n"];
    [mutableHeaderString appendString:@"\n"];
    
    [mutableHeaderString appendFormat:(NSString*)OBJ_C_INTERFACE, classname];
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
    
    [mutableHeaderString appendString:@"\n"];
    [mutableHeaderString appendString:(NSString*)OBJ_C_END];
}

@end
