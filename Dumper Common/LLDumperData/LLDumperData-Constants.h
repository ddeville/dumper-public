//
//  LLDumper-Constants.h
//  Dumper Common
//
//  Created by Damien DeVille on 12/17/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const LLDumperDataBundleIdentifier;

extern NSString * const LLDumperDataErrorDomain;

typedef NS_ENUM(NSInteger, LLDumperDataErrorCode) {
	LLDumperDataUnknownError = 0,
};

extern NSString * const LLDumperDocumentFileType;
