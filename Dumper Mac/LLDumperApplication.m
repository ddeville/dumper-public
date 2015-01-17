//
//  LLDumperApplication.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperApplication.h"

#import "LLDumperData/LLDumperData.h"

#define DIRECT_VERSION	defined(LL_BUILD_RELEASE_DIRECT)

#if DIRECT_VERSION
#import "Sparkle/Sparkle.h"
#import "LLRegistrationKit/LLRegistrationKit.h"
#endif /* DIRECT_VERSION */

#import "LLDumperDocument.h"
#import "LLDumperDocument+Private.h"

#import "LLDumperWelcomeWindowController.h"
#import "LLDumperPreferencesWindowController.h"

#import "NSURL+LLDumperExtensions.h"

#import "Dumper-Constants.h"
#import "Dumper-Defaults.h"

@interface LLDumperApplication () <NSApplicationDelegate>

@property (assign, nonatomic) IBOutlet NSMenuItem *checkForUpdateMenuItem, *viewLicenseMenuItem, *directSeparatorMenuItem;

@property (readwrite, strong, nonatomic) LLDumperThemeController *themeController;
#if DIRECT_VERSION
@property (strong, nonatomic) LLRegistrationController *registrationController;
#endif /* DIRECT_VERSION */

@property (readwrite, strong, nonatomic) LLDumperWelcomeWindowController *welcomeWindowController;
@property (readwrite, strong, nonatomic) LLDumperPreferencesWindowController *preferencesWindowController;

@property (assign, nonatomic) BOOL shouldOpenUntitledFile;
@property (assign, nonatomic) BOOL aboutToOpenDocumentAtLaunch;

@end

@implementation LLDumperApplication

+ (void)load
{
	@autoreleasepool {
		NSDictionary *registrationDefaults = @{
			@"NSApplicationCrashOnExceptions" : @YES,
			LLDumperShowWelcomeWindowAtLaunchDefault : @YES,
			@"SUFeedURL" : @"http://bananafishsoftware.com/feeds/dumper.xml",
		};
		[[NSUserDefaults standardUserDefaults] registerDefaults:registrationDefaults];
	}
}

+ (LLDumperApplication *)sharedApplication
{
	return (id)[super sharedApplication];
}

- (id)init
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	[self setDelegate:self];
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	_themeController = [[LLDumperThemeController alloc] init];
	
#if DIRECT_VERSION
	LLRegistrationController *registrationController = [[LLRegistrationController alloc] init];
	[registrationController setStoreURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/dumper/id781577745"]];
	_registrationController = registrationController;
#endif /* DIRECT_VERSION */
	
	_aboutToOpenDocumentAtLaunch = NO;
	
	LLDumperWelcomeWindowController *welcomeWindowController = [[LLDumperWelcomeWindowController alloc] init];
	_welcomeWindowController = welcomeWindowController;
	
	LLDumperPreferencesWindowController *preferencesWindowController = [[LLDumperPreferencesWindowController alloc] init];
	[preferencesWindowController setThemeController:_themeController];
	_preferencesWindowController = preferencesWindowController;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishRestoringWindows:) name:NSApplicationDidFinishRestoringWindowsNotification object:self];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishRestoringWindowsNotification object:self];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
#if !DIRECT_VERSION
	[[[self checkForUpdateMenuItem] menu] removeItem:[self checkForUpdateMenuItem]];
	[[[self viewLicenseMenuItem] menu] removeItem:[self viewLicenseMenuItem]];
	[[[self directSeparatorMenuItem] menu] removeItem:[self directSeparatorMenuItem]];
#endif /* !DIRECT_VERSION */
}

#pragma mark - NSApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	// nop
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
#if DIRECT_VERSION
	if ([[self registrationController] state] == LLRegistrationStateExpired) {
		[[self registrationController] showApplicationModalRegistrationWindow];
	}
#endif /* DIRECT_VERSION */
	
	if (![self aboutToOpenDocumentAtLaunch] && [[NSUserDefaults standardUserDefaults] boolForKey:LLDumperShowWelcomeWindowAtLaunchDefault]) {
		[self openWelcomeWindow:self];
	}
	
	[self setShouldOpenUntitledFile:YES];
}

- (void)applicationDidFinishRestoringWindows:(NSNotification *)notification
{
	// nop
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)application
{
	return [self shouldOpenUntitledFile];
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
	NSURL *fileURL = [NSURL fileURLWithPath:filename];
	if (fileURL == nil) {
		return NO;
	}
	
	NSString *fileUTType = nil;
	BOOL getFileUTType = [[fileURL URLByResolvingSymlinksInPath] getResourceValue:&fileUTType forKey:NSURLTypeIdentifierKey error:NULL];
	if (!getFileUTType) {
		return NO;
	}
	
	[self setAboutToOpenDocumentAtLaunch:YES];
	
	if (UTTypeConformsTo((__bridge CFStringRef)fileUTType, (__bridge CFStringRef)LLDumperDocumentFileType)) {
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES completionHandler:nil];
		
		return YES;
	}
	
	[self _startExtractingExecutableAtLocation:fileURL];
	
	return YES;
}

#pragma mark - URL Handling

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *eventURLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	if (eventURLString == nil) {
		return;
	}
	
	NSURL *eventURL = [NSURL URLWithString:eventURLString];
	if (eventURL == nil) {
		return;
	}
	
	NSString *action = [eventURL relativePath];
	if (action == nil) {
		return;
	}
	
	if (![action isEqualToString:LLDumperURLDumpAction]) {
		return;
	}
	
	NSDictionary *parameters = [eventURL ll_queryParameters];
	if (parameters[LLDumperURLDumpLocationKey] == nil) {
		return;
	}
	
	NSURL *location = [NSURL fileURLWithPath:parameters[LLDumperURLDumpLocationKey]];
	if (location == nil) {
		return;
	}
	
	[self setAboutToOpenDocumentAtLaunch:YES];
	
	[self _handleRemoteDumpAtLocation:location];
}

#pragma mark - Actions

- (IBAction)openPreferences:(id)sender
{
	[[self preferencesWindowController] showWindow:self];
}

- (IBAction)installCommandLineTools:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLocalizedString(@"Install Command Line Tools", @"LLDumperApplication install tools alert message text")];
	[alert setInformativeText:NSLocalizedString(@"You will need to download the installer for the Command Line Tools first. Once installed you will be able to use the dumper command line utility to create a Dumper document for an executable directly from the command line.", @"LLDumperApplication install tools alert informative text")];
	[alert addButtonWithTitle:NSLocalizedString(@"Download", @"LLDumperApplication install tools alert download button title")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"LLDumperApplication install tools alert cancel button title")];
	
	NSModalResponse response = [alert runModal];
	
	if (response == NSAlertFirstButtonReturn) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://bananafishsoftware.com/software/dumper/cli/dumper_cli.pkg"]];
	}
}

- (IBAction)checkForUpdates:(id)sender
{
#if DIRECT_VERSION
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
#else
	// nop
#endif /* DIRECT_VERSION */
}

- (IBAction)viewLicense:(id)sender
{
#if DIRECT_VERSION
	[[self registrationController] showApplicationModalRegistrationWindow];
#else
	// nop
#endif /* DIRECT_VERSION */
}

- (IBAction)openWelcomeWindow:(id)sender
{
	[[self welcomeWindowController] showWindow:self];
}

- (IBAction)openDumperSupport:(id)sender
{
	NSURL *dumperSupport = [NSURL URLWithString:@"http://bananafishsoftware.com/support/"];
	[[NSWorkspace sharedWorkspace] openURL:dumperSupport];
}

- (IBAction)openDumperProductPage:(id)sender
{
	NSURL *dumperProductPage = [NSURL URLWithString:@"http://bananafishsoftware.com/products/dumper/"];
	[[NSWorkspace sharedWorkspace] openURL:dumperProductPage];
}

- (IBAction)newDumperDocument:(id)sender
{
	[[self welcomeWindowController] close];
	[[NSDocumentController sharedDocumentController] newDocument:sender];
}

#pragma mark - Private

- (void)_handleRemoteDumpAtLocation:(NSURL *)fileURL
{
	void (^reportNotSupportedFileTypeError)(void) = ^ {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey : NSLocalizedString(@"Couldn\u2019t Dump Executable", @"LLDumperApplication cannot dump executable error description"),
			NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"There was an unknown error while processing the file at location \u201c%@\u201d. Please try again.", @"LLDumperApplication cannot dump executable error recovery suggestion"), [fileURL path]],
		};
		[self presentError:[NSError errorWithDomain:LLDumperErrorDomain code:LLDumperUnknownError userInfo:userInfo]];
	};
	
	if (![fileURL isFileURL]) {
		reportNotSupportedFileTypeError();
		return;
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
		reportNotSupportedFileTypeError();
		return;
	}
	
	if (![self _isFileTypeSupportedAtLocation:fileURL]) {
		reportNotSupportedFileTypeError();
		return;
	}
	
	[self _startExtractingExecutableAtLocation:fileURL];
}

- (BOOL)_isFileTypeSupportedAtLocation:(NSURL *)fileURL
{
	NSString *resourceType = nil;
	BOOL getResourceType = [fileURL getResourceValue:&resourceType forKey:NSURLTypeIdentifierKey error:NULL];
	if (!getResourceType) {
		return NO;
	}
	
	NSArray *applicationDocumentTypeDictionaries = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
	if (applicationDocumentTypeDictionaries == nil || [applicationDocumentTypeDictionaries count] == 0) {
		return NO;
	}
	
	NSMutableSet *applicationDocumentTypes = [NSMutableSet set];
	[applicationDocumentTypeDictionaries enumerateObjectsUsingBlock:^ (NSDictionary *fileTypes, NSUInteger idx, BOOL *stop) {
		[applicationDocumentTypes addObjectsFromArray:[fileTypes valueForKey:@"LSItemContentTypes"]];
	}];
	
	for (NSString *currentType in applicationDocumentTypes) {
		if (UTTypeConformsTo((__bridge CFStringRef)resourceType, (__bridge CFStringRef)currentType)) {
			return YES;
		}
	}
	
	return NO;
}

- (void)_startExtractingExecutableAtLocation:(NSURL *)fileURL
{
	LLDumperDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:NULL];
	[document extractHeadersInExectuableAtLocation:fileURL];
}

@end
