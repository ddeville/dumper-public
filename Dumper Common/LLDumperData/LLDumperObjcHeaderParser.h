//
//  LLDumperObjcHeaderParser.h
//  Dumper Common
//
//  Created by Damien DeVille on 12/19/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LLDumperObjcHeaderElement) {
	LLDumperObjcHeaderPlain = 0,
	LLDumperObjcHeaderAttribute = 1,
	LLDumperObjcHeaderKeyword = 2,
	LLDumperObjcHeaderClass = 3,
	LLDumperObjcHeaderComment = 4,
	LLDumperObjcHeaderPreprocessor = 5,
	LLDumperObjcHeaderString = 6,
};

@interface LLDumperObjcHeaderParser : NSObject

- (id)initWithHeaderContent:(NSString *)headerContent;

- (void)parse:(void (^)(LLDumperObjcHeaderElement element, NSRange range))visit;

@end
