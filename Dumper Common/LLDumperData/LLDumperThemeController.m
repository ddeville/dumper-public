//
//  LLDumperThemeController.m
//  Dumper Common
//
//  Created by Damien DeVille on 1/8/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import "LLDumperThemeController.h"

#import "LLDumperTheme.h"

#import "LLDumperData-Constants.h"

NSString * const LLDumperThemeControllerThemesKey = @"themes";
NSString * const LLDumperThemeControllerCurrentThemeKey = @"currentTheme";

static NSString * const LLDumperThemeControllerCurrentThemeIdentifierDefaultKey = @"currentThemeIdentifier";

@interface LLDumperTheme (/* Private */)

@property (readwrite, copy, nonatomic) NSString *identifier;
@property (readwrite, assign, nonatomic) BOOL editable;

@end

@interface LLDumperThemeController ()

@property (readwrite, strong, nonatomic) NSMutableArray *themes;

@end

@implementation LLDumperThemeController

static NSString * const _LLDumperThemeControllerPersistThemesNotification = @"_LLDumperThemeControllerPersistThemesNotification";

- (id)init
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	NSMutableArray *themes = [NSMutableArray array];
	[themes addObjectsFromArray:[[self class] defaultThemes]];
	[themes addObjectsFromArray:[[self class] _customThemes]];
	_themes = themes;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(__persistCustomThemes) name:_LLDumperThemeControllerPersistThemesNotification object:self];
	
	NSString *currentThemeIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:LLDumperThemeControllerCurrentThemeIdentifierDefaultKey];
	_currentTheme = [self _themeForIdentifier:currentThemeIdentifier] ? : [[[self class] defaultThemes] firstObject];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:_LLDumperThemeControllerPersistThemesNotification object:self];
}

#pragma mark - Properties

- (void)setCurrentTheme:(LLDumperTheme *)currentTheme
{
	[self willChangeValueForKey:LLDumperThemeControllerCurrentThemeKey];
	_currentTheme = currentTheme;
	[self didChangeValueForKey:LLDumperThemeControllerCurrentThemeKey];
	
	[[NSUserDefaults standardUserDefaults] setObject:[currentTheme identifier] forKey:LLDumperThemeControllerCurrentThemeIdentifierDefaultKey];
}

#pragma mark - Public

- (void)addTheme:(LLDumperTheme *)theme
{
	NSParameterAssert(theme != nil);
	
	[[self mutableArrayValueForKey:LLDumperThemeControllerThemesKey] addObject:theme];
	
	[self _setNeedsPersisting];
}

- (void)duplicateTheme:(LLDumperTheme *)theme
{
	LLDumperTheme *duplicateTheme = [[LLDumperTheme alloc] initWithPropertyListRepresentation:[theme propertyListRepresentation]];
	
	[duplicateTheme setName:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ Copy", nil, [NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier], @"LLDumperThemeController copy named"), [theme name]]];
	[duplicateTheme setIdentifier:[[NSUUID UUID] UUIDString]];
	[duplicateTheme setEditable:YES];
	
	[self addTheme:duplicateTheme];
}

- (void)removeTheme:(LLDumperTheme *)theme
{
	NSParameterAssert(theme != nil);
	
	[[self mutableArrayValueForKey:LLDumperThemeControllerThemesKey] removeObject:theme];
	
	[self _setNeedsPersisting];
}

- (void)updateTheme:(LLDumperTheme *)theme
{
	NSParameterAssert(theme != nil);
	
	NSUInteger idx = [[self themes] indexOfObject:theme];
	NSParameterAssert(idx != NSNotFound);
	
	[[self mutableArrayValueForKey:LLDumperThemeControllerThemesKey] replaceObjectAtIndex:idx withObject:theme];
	
	[self _setNeedsPersisting];
}

#pragma mark - Private

- (void)_setNeedsPersisting
{
	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:_LLDumperThemeControllerPersistThemesNotification object:self] postingStyle:NSPostWhenIdle coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender) forModes:@[NSDefaultRunLoopMode, NSRunLoopCommonModes]];
}

- (void)__persistCustomThemes
{
	NSMutableArray *customThemes = [NSMutableArray arrayWithArray:[self themes]];
	[customThemes removeObjectsInArray:[[self class] defaultThemes]];
	
	NSMutableArray *customThemesPropertyListRepresentation = [NSMutableArray arrayWithCapacity:[customThemes count]];
	[customThemes enumerateObjectsUsingBlock:^ (LLDumperTheme *theme, NSUInteger idx, BOOL *stop) {
		[customThemesPropertyListRepresentation addObject:[theme propertyListRepresentation]];
	}];
	
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:customThemesPropertyListRepresentation format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
	
	[data writeToURL:[[self class] _customThemesLocation] options:NSDataWritingAtomic error:NULL];
}

- (LLDumperTheme *)_themeForIdentifier:(NSString *)identifier
{
	if (identifier == nil) {
		return nil;
	}
	for (LLDumperTheme *theme in [self themes]) {
		if ([[theme identifier] isEqualToString:identifier]) {
			return theme;
		}
	}
	return nil;
}

+ (NSArray *)defaultThemes
{
	static NSMutableArray *_availableThemes = nil;
	
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^ {
		NSURL *themesLocation = [[NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier] URLForResource:@"LLObjcThemes" withExtension:@"plist"];
		_availableThemes = [NSMutableArray arrayWithArray:[self __retrieveThemesAtLocation:themesLocation]];
	});
	
	return _availableThemes;
}

+ (NSArray *)_customThemes
{
	return [self __retrieveThemesAtLocation:[self _customThemesLocation]];
}

+ (NSURL *)_customThemesLocation
{
	static NSURL *_customThemesLocation = nil;
	
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^ {
		NSURL *applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
		NSURL *dumperURL = [applicationSupportURL URLByAppendingPathComponent:@"Dumper"];
		[[NSFileManager defaultManager] createDirectoryAtURL:dumperURL withIntermediateDirectories:YES attributes:nil error:NULL];
		
		_customThemesLocation = [[dumperURL URLByAppendingPathComponent:@"LLObjcThemes"] URLByAppendingPathExtension:@"plist"];
	});
	
	return _customThemesLocation;
}

+ (NSArray *)__retrieveThemesAtLocation:(NSURL *)location
{
	NSArray *themesPropertyListRepresentation = [NSArray arrayWithContentsOfURL:location];
	
	NSMutableArray *themes = [NSMutableArray array];
	
	[themesPropertyListRepresentation enumerateObjectsUsingBlock:^ (id value, NSUInteger idx, BOOL *stop) {
		LLDumperTheme *theme = [[LLDumperTheme alloc] initWithPropertyListRepresentation:value];
		[themes addObject:theme];
	}];
	
	return themes;
}

@end
