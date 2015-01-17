//
//  Dumper-Constants.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const LLDumperBundleIdentifier;

extern NSString * const LLDumperErrorDomain;

typedef NS_ENUM(NSInteger, LLDumperErrorCode) {
	LLDumperUnknownError = 0,
	
	LLDumperClassDumpError = -100,
};

extern NSString * const LLDumperURLScheme;
	extern NSString * const LLDumperURLDumpAction;
	extern NSString * const LLDumperURLDumpLocationKey;
