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

#ifndef DLError_h
#define DLError_h

extern const NSErrorDomain ERRORDOMAIN_NOT_ENOUGH_ARGUMENT;

typedef NS_ENUM(NSInteger, DLErrorCode) {
    NOT_ENOUGH_ARGUMENTS,
};

@interface DLError : NSError

+(DLError*)notEnoughArguments;
-(void)terminateProgram;

@end

#endif /* DLError_h */
