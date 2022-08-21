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

#import "DLMainImage.h"

NSString* buildVersionNumberAsString(MKDylibVersion *dylibVersion);
void determinePathLocation(NSString *imagePath);

@implementation DLMainImage

-(instancetype)initWithMainDylib:(MKLCIDDylib*)mainDylib {
    NSURL *imageUrl = [NSURL fileURLWithPath:mainDylib.name.string];
    
    // "/System/Library/Frameworks/Metal.framework/Versions/A/Metal" returns "Metal"
    // ""
    _imageName = [[[imageUrl.pathComponents lastObject] componentsSeparatedByString:@"."] firstObject];
    [self determineLocationUsingPath:imageUrl];
    
    _currentVersion = buildVersionNumberAsString(mainDylib.current_version);
    _compabilityVersion = buildVersionNumberAsString(mainDylib.compatibility_version);
    
    return self;
}

-(void)determineLocationUsingPath:(NSURL*)imageUrl {
    _imagePath = imageUrl.path;
    
    if ([_imagePath hasSuffix: @".dylib"]) {
        _imageType = ImageTypeDylib;
        _frameworkLocation = FrameworkLocationNotApplicable;
        _frameworkType = FrameworkTypeNotApplicable;
    } else if ([_imagePath hasPrefix:@"/System/Library/PrivateFrameworks/"]) {
        _imageType = ImageTypeFramework;
        _frameworkLocation = FrameworkLocationDefault;
        _frameworkType = FrameworkTypePrivate;
    } else if ([_imagePath hasPrefix:@"/System/Library/Frameworks/"]) {
        _imageType = ImageTypeFramework;
        _frameworkLocation = FrameworkLocationDefault;
        _frameworkType = FrameworkTypePublic;
    } else if ([_imagePath hasPrefix:@"/System/iOSSupport/System/Library/PrivateFrameworks/"]) {
        _imageType = ImageTypeFramework;
        _frameworkLocation = FrameworkLocationIOSSupport;
        _frameworkType = FrameworkTypePrivate;
    } else if ([_imagePath hasPrefix:@"/System/iOSSupport/System/Library/Frameworks/"]) {
        _imageType = ImageTypeFramework;
        _frameworkLocation = FrameworkLocationIOSSupport;
        _frameworkType = FrameworkTypePublic;
    }
}

@end

NSString* buildVersionNumberAsString(MKDylibVersion *dylibVersion) {
    return [NSString stringWithFormat:@"%i.%i.%i",
            dylibVersion.major,
            dylibVersion.minor,
            dylibVersion.patch];
}
