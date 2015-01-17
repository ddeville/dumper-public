//
//  LLDumperObjcHeaderParser.m
//  Dumper Common
//
//  Created by Damien DeVille on 12/19/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperObjcHeaderParser.h"

#import "LLDumperData-Constants.h"

@interface LLDumperObjcHeaderParser ()

@property (copy, nonatomic) NSString *headerContent;

@end

@implementation LLDumperObjcHeaderParser

+ (NSSet *)_objcAttributes
{
	static NSSet *objcAttributes = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^ {
		NSURL *attributesLocation = [[NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier] URLForResource:@"LLObjcAttributes" withExtension:@"plist"];
		NSArray *attributes = [NSArray arrayWithContentsOfURL:attributesLocation];
		objcAttributes = [NSSet setWithArray:attributes];
	});
	return objcAttributes;
}

+ (NSSet *)_objcKeywords
{
	static NSSet *objcKeywords = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^ {
		NSURL *keywordsLocation = [[NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier] URLForResource:@"LLObjcKeywords" withExtension:@"plist"];
		NSArray *keywords = [NSArray arrayWithContentsOfURL:keywordsLocation];
		objcKeywords = [NSSet setWithArray:keywords];
	});
	return objcKeywords;
}

+ (NSCharacterSet *)_objcSymbolsCharacterSet
{
	static NSCharacterSet *_objcSymbolsCharacterSet = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^ {
		NSMutableCharacterSet *objcSymbolsCharacterSet = [[NSMutableCharacterSet alloc] init];
		[objcSymbolsCharacterSet addCharactersInString:@"*"];
		[objcSymbolsCharacterSet addCharactersInString:@"-"];
		[objcSymbolsCharacterSet addCharactersInString:@"+"];
		[objcSymbolsCharacterSet addCharactersInString:@"="];
		[objcSymbolsCharacterSet addCharactersInString:@"^"];
		[objcSymbolsCharacterSet addCharactersInString:@"<"];
		[objcSymbolsCharacterSet addCharactersInString:@">"];
		[objcSymbolsCharacterSet addCharactersInString:@"("];
		[objcSymbolsCharacterSet addCharactersInString:@")"];
		[objcSymbolsCharacterSet addCharactersInString:@"{"];
		[objcSymbolsCharacterSet addCharactersInString:@"}"];
		[objcSymbolsCharacterSet addCharactersInString:@"["];
		[objcSymbolsCharacterSet addCharactersInString:@"]"];
		[objcSymbolsCharacterSet addCharactersInString:@"|"];
		[objcSymbolsCharacterSet addCharactersInString:@"&"];
		[objcSymbolsCharacterSet addCharactersInString:@"~"];
		[objcSymbolsCharacterSet addCharactersInString:@"?"];
		[objcSymbolsCharacterSet addCharactersInString:@":"];
		[objcSymbolsCharacterSet addCharactersInString:@";"];
		[objcSymbolsCharacterSet addCharactersInString:@","];
		_objcSymbolsCharacterSet = objcSymbolsCharacterSet;
	});
	return _objcSymbolsCharacterSet;
}

- (id)initWithHeaderContent:(NSString *)headerContent
{
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	_headerContent = [headerContent copy];
	
	return self;
}

- (void)parse:(void (^)(LLDumperObjcHeaderElement element, NSRange range))visit
{
	NSParameterAssert(visit != nil);
	
	NSMutableCharacterSet *delimiterCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	[delimiterCharacterSet formUnionWithCharacterSet:[[self class] _objcSymbolsCharacterSet]];
	
	NSScanner *scanner = [[NSScanner alloc] initWithString:[self headerContent]];
	[scanner setCharactersToBeSkipped:nil];
	
	void (^scanOne)(void) = ^ {
		if (![scanner isAtEnd]) {
			[scanner setScanLocation:([scanner scanLocation] + 1)];
		}
	};
	
	while (![scanner isAtEnd]) {
		NSUInteger scanLocation = [scanner scanLocation];
		
		if ([scanner scanString:@"//" intoString:NULL]) {
			NSString *comment = nil;
			[scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&comment];
			scanOne();
			
			visit(LLDumperObjcHeaderComment, NSMakeRange(scanLocation, [scanner scanLocation] - scanLocation));
		}
		else if ([scanner scanString:@"/*" intoString:NULL]) {
			NSString *multineComment = nil;
			[scanner scanUpToString:@"*/" intoString:&multineComment];
			scanOne();
			
			visit(LLDumperObjcHeaderComment, NSMakeRange(scanLocation, [scanner scanLocation] - scanLocation));
		}
		else if ([scanner scanString:@"#" intoString:NULL]) {
			NSString *preprocessor = nil;
			[scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&preprocessor];
			scanOne();
			
			if (preprocessor != nil) {
				preprocessor = [@"#" stringByAppendingString:preprocessor];
			}
			[self _scanPreprocessorDirective:preprocessor originalLocation:scanLocation visit:visit];
		}
		else if ([scanner scanString:@"@\"" intoString:NULL]) {
			NSString *objcString = nil;
			[scanner scanUpToString:@"\"" intoString:&objcString];
			scanOne();
			
			visit(LLDumperObjcHeaderString, NSMakeRange(scanLocation, [scanner scanLocation] - scanLocation));
		}
		else if ([scanner scanString:@"\"" intoString:NULL]) {
			NSString *string = nil;
			[scanner scanUpToString:@"\"" intoString:&string];
			scanOne();
			
			visit(LLDumperObjcHeaderString, NSMakeRange(scanLocation, [scanner scanLocation] - scanLocation));
		}
		else {
			NSString *word = nil;
			BOOL scan = [scanner scanUpToCharactersFromSet:delimiterCharacterSet intoString:&word];
			if (scan) {
				[self _scanWord:word originalLocation:scanLocation visit:visit];
			}
			else {
				[scanner scanCharactersFromSet:delimiterCharacterSet intoString:NULL];
			}
		}
	}
}

- (void)_scanPreprocessorDirective:(NSString *)preprocessorDirective originalLocation:(NSUInteger)originalLocation visit:(void (^)(LLDumperObjcHeaderElement element, NSRange range))visit
{
	NSMutableCharacterSet *delimiterCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	[delimiterCharacterSet formUnionWithCharacterSet:[[self class] _objcSymbolsCharacterSet]];
	
	NSScanner *preprocessorScanner = [[NSScanner alloc] initWithString:preprocessorDirective];
	
	void (^scanOne)(void) = ^ {
		if (![preprocessorScanner isAtEnd]) {
			[preprocessorScanner setScanLocation:([preprocessorScanner scanLocation] + 1)];
		}
	};
	
	NSUInteger (^_scanLocation)(NSUInteger) = ^ NSUInteger (NSUInteger location) {
		return originalLocation + location;
	};
	
	while (![preprocessorScanner isAtEnd]) {
		NSUInteger scanLocation = _scanLocation([preprocessorScanner scanLocation]);
		
		if ([preprocessorScanner scanString:@"\"" intoString:NULL]) {
			NSString *string = nil;
			[preprocessorScanner scanUpToString:@"\"" intoString:&string];
			scanOne();
			
			visit(LLDumperObjcHeaderString, NSMakeRange(scanLocation, _scanLocation([preprocessorScanner scanLocation]) - scanLocation));
		}
		else if ([preprocessorScanner scanString:@"<" intoString:NULL]) {
			NSString *string = nil;
			[preprocessorScanner scanUpToString:@">" intoString:&string];
			scanOne();
			
			visit(LLDumperObjcHeaderString, NSMakeRange(scanLocation, _scanLocation([preprocessorScanner scanLocation]) - scanLocation));
		}
		else {
			NSString *word = nil;
			BOOL scan = [preprocessorScanner scanUpToCharactersFromSet:delimiterCharacterSet intoString:&word];
			if (scan) {
				visit(LLDumperObjcHeaderPreprocessor, NSMakeRange(scanLocation, _scanLocation([preprocessorScanner scanLocation]) - scanLocation));
			}
			else {
				[preprocessorScanner scanCharactersFromSet:delimiterCharacterSet intoString:NULL];
			}
		}
	}
}

- (void)_scanWord:(NSString *)word originalLocation:(NSUInteger)originalLocation visit:(void (^)(LLDumperObjcHeaderElement element, NSRange range))visit
{
	NSRange range = NSMakeRange(originalLocation, [word length]);
	
	if ([[[self class] _objcAttributes] containsObject:word]) {
		visit(LLDumperObjcHeaderAttribute, range);
		return;
	}
	
	if ([[[self class] _objcKeywords] containsObject:word]) {
		visit(LLDumperObjcHeaderKeyword, range);
		return;
	}
	
	BOOL (^uppercase)(NSString *) = ^ BOOL (NSString *string) {
		return ([string length] > 0 && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[string characterAtIndex:0]]);
	};
	
	if (uppercase(word) || uppercase([word stringByReplacingOccurrencesOfString:@"_" withString:@""])) {
		visit(LLDumperObjcHeaderClass, range);
		return;
	}

	visit(LLDumperObjcHeaderPlain, range);
}

@end
