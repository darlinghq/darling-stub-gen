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

typedef NS_ENUM(NSUInteger, DLMainImageImageType) {
    ImageTypeDylib,
    ImageTypeFramework,
};

typedef NS_ENUM(NSUInteger, DLMainImageFrameworkType) {
    FrameworkTypeNotApplicable,
    FrameworkTypePublic,
    FrameworkTypePrivate,
};

typedef NS_ENUM(NSUInteger, DLMainImageFrameworkLocation) {
    FrameworkLocationNotApplicable,
    FrameworkLocationDefault,
    FrameworkLocationIOSSupport,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLMainImage : NSObject

@property(readonly) NSString *imagePath;

@property(readonly) DLMainImageImageType imageType;
@property(readonly) DLMainImageFrameworkType frameworkType;
@property(readonly) DLMainImageFrameworkLocation frameworkLocation;

@property(readonly) NSString *imageName;
@property(readonly) NSString *currentVersion;
@property(readonly) NSString *compabilityVersion;

-(instancetype)initWithMainDylib:(MKLCIDDylib*)mainDylib;

@end

NS_ASSUME_NONNULL_END
