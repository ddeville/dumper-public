//
//  LLDumperDocument.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDocument.h"
#import "LLDumperDocument+Private.h"

#import "LLDumperData/LLDumperData.h"
#import "ClassDump/ClassDump.h"

#import "LLDumperDocumentWindowController.h"
#import "LLDumperDocumentWindowController+Private.h"

#import "Dumper-Constants.h"

@interface LLDumperDocument (/* User interface */)

@property (strong, nonatomic) LLDumperDocumentWindowController *dumperDocumentWindowController;

@end

@interface LLDumperDocument (/* Data */)

@property (strong, nonatomic) LLDumperDocumentStorage *storage;

@property (copy, nonatomic) NSURL *directoryToDeleteOnSave;

@end

@implementation LLDumperDocument

+ (BOOL)autosavesInPlace
{
	return YES;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

+ (BOOL)autosavesDrafts
{
	return YES;
}

- (id)init
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	_storage = [[LLDumperDocumentStorage alloc] initWithFileType:[self fileType]];
	
	return self;
}

#pragma mark - User interface

- (void)makeWindowControllers
{
	LLDumperDocumentWindowController *dumperDocumentWindowController = [[LLDumperDocumentWindowController alloc] init];
	[self setDumperDocumentWindowController:dumperDocumentWindowController];
	[self addWindowController:dumperDocumentWindowController];
}

#pragma mark - Data

- (NSString *)fileType
{
	return LLDumperDocumentFileType;
}

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
{
	return YES;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)errorRef
{
	return [[self storage] fileWrapperOfType:typeName error:errorRef];
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)errorRef
{
	return [[self storage] loadFromContents:fileWrapper ofType:typeName error:errorRef];
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)errorRef
{
	BOOL write = [super writeToURL:url ofType:typeName error:errorRef];
	if (!write) {
		return NO;
	}
	
	if ([self directoryToDeleteOnSave] != nil) {
		[[NSFileManager defaultManager] removeItemAtURL:[self directoryToDeleteOnSave] error:NULL];
	}
	
	return YES;
}

#pragma mark - Public

- (void)extractHeadersInExectuableAtLocation:(NSURL *)bundleOrExecutableLocation
{
	[[self dumperDocumentWindowController] _prepareInterfaceForExtractingHeadersInExecutableAtLocation:bundleOrExecutableLocation];
}

- (NSArray *)headerFilenames
{
	return [[self storage] sortedHeaderFilenames];
}

- (NSString *)headerContentWithFilename:(NSString *)filename
{
	return [[self storage] headers][filename];
}

- (NSDictionary *)headers
{
	return [[self storage] headers];
}

#pragma mark - Public helpers

+ (NSArray *)allowedImportFileTypes
{
	return @[(id)kUTTypeFramework, (id)kUTTypeApplicationBundle, @"public.executable"];
}

+ (NSOpenPanel *)importOpenPanel
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setCanSelectHiddenExtension:YES];
	[openPanel setExtensionHidden:NO];
	[openPanel setShowsHiddenFiles:YES];
	[openPanel setTreatsFilePackagesAsDirectories:NO];
	[openPanel setAllowedFileTypes:[self allowedImportFileTypes]];
	
	return  openPanel;
}

#pragma mark - Private

- (void)_extractHeadersInExectuableAtLocation:(NSURL *)bundleOrExecutableLocation completion:(void (^)(BOOL success, NSError *error))completion
{
	completion = completion ? : ^ (BOOL success, NSError *error) {};
	
	NSURL *exportDirectoryLocation = [self _makeTemporaryDirectoryForImport];
	
	CDClassDumpOperation *classDumpOperation = [[CDClassDumpOperation alloc] initWithBundleOrExecutableLocation:bundleOrExecutableLocation exportDirectoryLocation:exportDirectoryLocation];
	[[[NSOperationQueue alloc] init] addOperation:classDumpOperation];
	
	NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^ {
		NSError *error = nil;
		id result = [classDumpOperation completionProvider](&error);
		if (result == nil) {
			completion(NO, error);
			[self presentError:error modalForWindow:[[self dumperDocumentWindowController] window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
			return;
		}
		
		NSError *addHeadersError = nil;
		BOOL addHeaders = [self _importHeaderFilesFromDirectory:exportDirectoryLocation deleteOriginalOnSave:YES error:&addHeadersError];
		if (!addHeaders) {
			completion(NO, addHeadersError);
			[self presentError:addHeadersError modalForWindow:[[self dumperDocumentWindowController] window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
			return;
		}
		
		[self setDisplayName:[[bundleOrExecutableLocation lastPathComponent] stringByDeletingPathExtension]];
		[self autosaveDocumentWithDelegate:nil didAutosaveSelector:NULL contextInfo:NULL];
		
		completion(YES, nil);
	}];
	[completionOperation addDependency:classDumpOperation];
	[[NSOperationQueue mainQueue] addOperation:completionOperation];
}

- (BOOL)_importHeaderFilesFromDirectory:(NSURL *)directoryLocation deleteOriginalOnSave:(BOOL)deleteOriginalOnSave error:(NSError **)errorRef
{
	NSArray *headerLocations = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryLocation includingPropertiesForKeys:nil options:(NSDirectoryEnumerationOptions)0 error:errorRef];
	if (headerLocations == nil) {
		return NO;
	}
	
	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:[headerLocations count]];
	
	[headerLocations enumerateObjectsUsingBlock:^ (NSURL *headerLocation, NSUInteger idx, BOOL *stop) {
		NSString *filename = [headerLocation lastPathComponent];
		NSString *contents = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:headerLocation] encoding:NSUTF8StringEncoding];
		[headers setValue:contents forKey:filename];
	}];
	
	[[self storage] setHeaders:headers];
	
	if (deleteOriginalOnSave) {
		[self setDirectoryToDeleteOnSave:directoryLocation];
	}
	
	[self updateChangeCount:NSChangeDone];
	
	return YES;
}

- (NSURL *)_makeTemporaryDirectoryForImport
{
	return [[[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:LLDumperBundleIdentifier] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
}

@end
