//
//  LLDumperTheme.m
//  Dumper Common
//
//  Created by Damien DeVille on 12/20/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperTheme.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif /* TARGET_OS_IPHONE */

#import "LLDumperThemeController.h"

NSString * const LLDumperThemeIdentifierKey = @"identifier";
NSString * const LLDumperThemeNameKey = @"name";
NSString * const LLDumperThemeEditableKey = @"editable";
NSString * const LLDumperThemeBackgroundColorKey = @"backgroundColor";
NSString * const LLDumperThemeSelectionColorKey = @"selectionColor";
NSString * const LLDumperThemePlainColorKey = @"plainColor";
NSString * const LLDumperThemeAttributeColorKey = @"attributeColor";
NSString * const LLDumperThemeKeywordColorKey = @"keywordColor";
NSString * const LLDumperThemeClassColorKey = @"classColor";
NSString * const LLDumperThemeCommentColorKey = @"commentColor";
NSString * const LLDumperThemePreprocessorColorKey = @"preprocessorColor";
NSString * const LLDumperThemeStringColorKey = @"stringColor";

@interface LLDumperTheme ()

@property (readwrite, copy, nonatomic) NSString *identifier;
@property (readwrite, assign, nonatomic) BOOL editable;

@end

@implementation LLDumperTheme

- (id)init
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	_identifier = [[NSUUID UUID] UUIDString];
	_name = NSLocalizedString(@"New Theme", @"LLDumperTheme new theme name");
	_editable = YES;
	
	[self _setupDefaultColors];
	
	return self;
}

- (BOOL)isEqual:(id)object
{
	if (![super isEqual:object]) {
		return NO;
	}
	return [[self identifier] isEqualToString:[object identifier]];
}

- (NSUInteger)hash
{
	return [[self identifier] hash];
}

- (void)updateColorsFromTheme:(LLDumperTheme *)theme
{
	NSMutableArray *colorKeyPaths = [NSMutableArray arrayWithArray:[self _textColorKeyPaths]];
	[colorKeyPaths addObjectsFromArray:@[LLDumperThemeBackgroundColorKey, LLDumperThemeSelectionColorKey]];
	
	[colorKeyPaths enumerateObjectsUsingBlock:^ (NSString *keyPath, NSUInteger idx, BOOL *stop) {
		[self setValue:[theme valueForKeyPath:keyPath] forKeyPath:keyPath];
	}];
}

- (NSArray *)_textColorKeyPaths
{
	return @[LLDumperThemePlainColorKey, LLDumperThemeAttributeColorKey, LLDumperThemeKeywordColorKey, LLDumperThemeClassColorKey, LLDumperThemeCommentColorKey, LLDumperThemePreprocessorColorKey, LLDumperThemeStringColorKey];
}

- (void)_setupDefaultColors
{
	NSArray *textKeyPaths = [self _textColorKeyPaths];
	
#if TARGET_OS_IPHONE
	[self setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
	[self setSelectionColor:[UIColor colorWithRed:0.72 green:0.72 blue:0.72 alpha:1.0]];
	
	for (NSString *keyPath in textKeyPaths) {
		[self setValue:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] forKey:keyPath];
	}
#else
	[self setBackgroundColor:[[NSColor textBackgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]];
	[self setSelectionColor:[[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]];
	
	for (NSString *keyPath in textKeyPaths) {
		[self setValue:[[NSColor textColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] forKeyPath:keyPath];
	}
#endif /* TARGET_OS_IPHONE */
}

- (void)_populateColorKeyPath:(NSString *)keyPath storage:(NSDictionary *)propertyListRepresentation key:(NSString *)key
{
	id color = [self _retrieveColor:propertyListRepresentation forKey:key];
	[self setValue:color forKeyPath:keyPath];
}

- (id)_retrieveColor:(NSDictionary *)propertyListRepresentation forKey:(NSString *)key
{
	NSString *value = propertyListRepresentation[key];
	if (value == nil || ![value isKindOfClass:[NSString class]]) {
		return nil;
	}
	
	NSScanner *scanner = [[NSScanner alloc] initWithString:value];
	
	NSMutableCharacterSet *charactersToBeSkipped = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	[charactersToBeSkipped addCharactersInString:@","];
	[scanner setCharactersToBeSkipped:charactersToBeSkipped];
	
	NSInteger red = 0, green = 0, blue = 0;
	double alpha = 0.0;
	
	[scanner scanInteger:&red];
	[scanner scanInteger:&green];
	[scanner scanInteger:&blue];
	[scanner scanDouble:&alpha];
	
	CGFloat components[4] = {(CGFloat)red / 255.0, (CGFloat)green / 255.0, (CGFloat)blue / 255.0, alpha};
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef color = CGColorCreate(colorSpace, components);
	CGColorSpaceRelease(colorSpace);
	
	id nativeColor = nil;
#if TARGET_OS_IPHONE
	nativeColor = [UIColor colorWithCGColor:color];
#else
	nativeColor = [NSColor colorWithCGColor:color];
#endif /* TARGET_OS_IPHONE */
	
	CGColorRelease(color);
	
	return nativeColor;
}

- (NSString *)_encodedColorRepresentation:(id)nativeColor
{
#if !TARGET_OS_IPHONE
	nativeColor = [nativeColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
#endif /* TARGET_OS_IPHONE */
	
	CGColorRef color = [nativeColor CGColor];
	
	CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
	CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
	
	if (colorSpaceModel != kCGColorSpaceModelRGB) {
		return nil;
	}
	
	const CGFloat *components = CGColorGetComponents(color);
	
	NSArray *colorComponents = @[
		@((NSUInteger)(components[0] * 255)),
		@((NSUInteger)(components[1] * 255)),
		@((NSUInteger)(components[2] * 255)),
		@(components[3]),
	];
	
	return [colorComponents componentsJoinedByString:@","];
}

@end

#pragma mark -

@implementation LLDumperTheme (PropertyList)

- (id)initWithPropertyListRepresentation:(id)propertyListRepresentation
{
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	[self _retrieveAndPopulateColors:propertyListRepresentation];
	
	return self;
}

- (id)propertyListRepresentation
{
	return [self _encodeColors];
}

- (void)_retrieveAndPopulateColors:(NSDictionary *)propertyListRepresentation
{
	[self setIdentifier:propertyListRepresentation[LLDumperThemeIdentifierKey]];
	[self setName:propertyListRepresentation[LLDumperThemeNameKey]];
	[self setEditable:[propertyListRepresentation[LLDumperThemeEditableKey] boolValue]];
	
	[self _populateColorKeyPath:LLDumperThemeBackgroundColorKey storage:propertyListRepresentation key:LLDumperThemeBackgroundColorKey];
	[self _populateColorKeyPath:LLDumperThemeSelectionColorKey storage:propertyListRepresentation key:LLDumperThemeSelectionColorKey];
	[self _populateColorKeyPath:LLDumperThemePlainColorKey storage:propertyListRepresentation key:LLDumperThemePlainColorKey];
	[self _populateColorKeyPath:LLDumperThemeAttributeColorKey storage:propertyListRepresentation key:LLDumperThemeAttributeColorKey];
	[self _populateColorKeyPath:LLDumperThemeKeywordColorKey storage:propertyListRepresentation key:LLDumperThemeKeywordColorKey];
	[self _populateColorKeyPath:LLDumperThemeClassColorKey storage:propertyListRepresentation key:LLDumperThemeClassColorKey];
	[self _populateColorKeyPath:LLDumperThemeCommentColorKey storage:propertyListRepresentation key:LLDumperThemeCommentColorKey];
	[self _populateColorKeyPath:LLDumperThemePreprocessorColorKey storage:propertyListRepresentation key:LLDumperThemePreprocessorColorKey];
	[self _populateColorKeyPath:LLDumperThemeStringColorKey storage:propertyListRepresentation key:LLDumperThemeStringColorKey];
}

- (id)_encodeColors
{
	NSMutableDictionary *propertyListRepresentation = [NSMutableDictionary dictionary];
	
	[propertyListRepresentation setValue:[self identifier] forKey:LLDumperThemeIdentifierKey];
	[propertyListRepresentation setValue:[self name] forKey:LLDumperThemeNameKey];
	[propertyListRepresentation setValue:@([self isEditable]) forKey:LLDumperThemeEditableKey];
	
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self backgroundColor]] forKey:LLDumperThemeBackgroundColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self selectionColor]] forKey:LLDumperThemeSelectionColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self plainColor]] forKey:LLDumperThemePlainColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self attributeColor]] forKey:LLDumperThemeAttributeColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self keywordColor]] forKey:LLDumperThemeKeywordColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self classColor]] forKey:LLDumperThemeClassColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self commentColor]] forKey:LLDumperThemeCommentColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self preprocessorColor]] forKey:LLDumperThemePreprocessorColorKey];
	[propertyListRepresentation setValue:[self _encodedColorRepresentation:[self stringColor]] forKey:LLDumperThemeStringColorKey];
	
	return propertyListRepresentation;
}

@end