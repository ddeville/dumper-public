//
//  LLDumperObjcHeaderSyntaxHighlighter.m
//  Dumper Common
//
//  Created by Damien DeVille on 12/19/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperObjcHeaderSyntaxHighlighter.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif /* TARGET_OS_IPHONE */

#import "LLDumperObjcHeaderParser.h"
#import "LLDumperTheme.h"

@implementation LLDumperObjcHeaderSyntaxHighlighter

+ (NSAttributedString *)syntaxHighlightedHeaderContent:(NSString *)headerContent theme:(LLDumperTheme *)theme
{
	return [self _createSyntaxHighlightedHeaderContent:headerContent theme:theme];
}

+ (id)backgroundColorForTheme:(LLDumperTheme *)theme
{
	return [theme backgroundColor];
}

+ (NSDictionary *)selectedTextAttributesForTheme:(LLDumperTheme *)theme
{
	id selectionColor = [theme selectionColor];
	if (selectionColor == nil) {
		return nil;
	}
	return @{NSBackgroundColorAttributeName : selectionColor};
}

#pragma mark - Private

+ (NSAttributedString *)_createSyntaxHighlightedHeaderContent:(NSString *)headerContent theme:(LLDumperTheme *)theme
{
	if (headerContent == nil) {
		return nil;
	}
	
	NSDictionary *originalAttributes = @{NSForegroundColorAttributeName : (_LLDumperColorForElement(LLDumperObjcHeaderPlain, theme) ? : [self _defaultTextColor])};
	NSMutableAttributedString *highlightedHeaderContent = [[NSMutableAttributedString alloc] initWithString:headerContent attributes:originalAttributes];
	
	LLDumperObjcHeaderParser *parser = [[LLDumperObjcHeaderParser alloc] initWithHeaderContent:headerContent];
	
	[parser parse:^ (LLDumperObjcHeaderElement element, NSRange range) {
		id color = _LLDumperColorForElement(element, theme);
		if (color != nil) {
			[highlightedHeaderContent setAttributes:@{NSForegroundColorAttributeName : color} range:range];
		}
	}];
	
	return highlightedHeaderContent;
}

+ (id)_defaultTextColor
{
#if TARGET_OS_IPHONE
	return [UIColor whiteColor];
#else
	return [NSColor whiteColor];
#endif /* TARGET_OS_IPHONE */
}

#pragma mark - Functions

static id _LLDumperColorForElement(LLDumperObjcHeaderElement element, LLDumperTheme *theme) {
	id color = [theme valueForKeyPath:_LLDumperThemeKeypathForElement(element)];
	if (color != nil) {
		return color;
	}
	return [theme valueForKeyPath:_LLDumperThemeKeypathForElement(element)];
}

static NSString *_LLDumperThemeKeypathForElement(LLDumperObjcHeaderElement element) {
	switch (element) {
		case LLDumperObjcHeaderPlain:
		default:
			return LLDumperThemePlainColorKey;
		case LLDumperObjcHeaderComment:
			return LLDumperThemeCommentColorKey;
		case LLDumperObjcHeaderPreprocessor:
			return LLDumperThemePreprocessorColorKey;
		case LLDumperObjcHeaderString:
			return LLDumperThemeStringColorKey;
		case LLDumperObjcHeaderAttribute:
			return LLDumperThemeAttributeColorKey;
		case LLDumperObjcHeaderKeyword:
			return LLDumperThemeKeywordColorKey;
		case LLDumperObjcHeaderClass:
			return LLDumperThemeClassColorKey;
	}
}

@end
