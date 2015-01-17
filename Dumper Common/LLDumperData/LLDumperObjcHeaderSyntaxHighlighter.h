//
//  LLDumperObjcHeaderSyntaxHighlighter.h
//  Dumper Common
//
//  Created by Damien DeVille on 12/19/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LLDumperTheme;

@interface LLDumperObjcHeaderSyntaxHighlighter : NSObject

+ (NSAttributedString *)syntaxHighlightedHeaderContent:(NSString *)headerContent theme:(LLDumperTheme *)theme;

+ (id)backgroundColorForTheme:(LLDumperTheme *)theme;
+ (NSDictionary *)selectedTextAttributesForTheme:(LLDumperTheme *)theme;

@end
