//
//  LLDumperDocumentHeadersExportOperation.m
//  Dumper Common
//
//  Created by Damien DeVille on 12/17/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDocumentHeadersExportOperation.h"

#import "LLDumperData-Constants.h"

@interface LLDumperDocumentHeadersExportOperation ()

@property (strong, nonatomic) NSDictionary *headers;
@property (copy, nonatomic) NSURL *exportLocation;

@property (readwrite, copy, atomic) NSURL * (^completionProvider)(NSError **errorRef);

@end

@implementation LLDumperDocumentHeadersExportOperation

- (id)initWithHeaders:(NSDictionary *)headers exportLocation:(NSURL *)exportLocation
{
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	_headers = headers;
	_exportLocation = [exportLocation copy];
	
	return self;
}

- (void)main
{
	NSURL *exportURL = [self exportLocation];
	
	NSError *temporaryDirectoryCreationError = nil;
	NSURL *temporaryDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:exportURL create:YES error:&temporaryDirectoryCreationError];
	if (temporaryDirectoryURL == nil) {
		[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
			if (errorRef != NULL) {
				*errorRef = temporaryDirectoryCreationError;
			}
			return nil;
		}];
		
		return;
	}
	
	NSMutableArray *writeErrors = [NSMutableArray array];
	
	[[self headers] enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^ (NSString *filename, NSString *content, BOOL *stop) {
		NSURL *exportURL = [temporaryDirectoryURL URLByAppendingPathComponent:filename];
		
		NSError *writeError = nil;
		BOOL write = [content writeToURL:exportURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
		
		if (!write) {
			[writeErrors addObject:writeError];
		}
	}];
	
	NSURL *resultingExportLocation = nil;
	NSError *replacementError = nil;
	BOOL replace = [[NSFileManager defaultManager] replaceItemAtURL:exportURL withItemAtURL:temporaryDirectoryURL backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingExportLocation error:&replacementError];
	
	if (!replace) {
		[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
			if (errorRef != NULL) {
				*errorRef = replacementError;
			}
			return nil;
		}];
		
		return;
	}
	
	if ([writeErrors count] > 0) {
		[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
			if (errorRef != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"Couldn\u2019t export some headers", nil, [NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier], @"LLDumperDocumentHeadersExportOperation unknown export error description"),
					NSLocalizedRecoverySuggestionErrorKey : NSLocalizedStringFromTableInBundle(@"There was an unknown error while exporing some headers.", nil, [NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier], @"LLDumperDocumentHeadersExportOperation unknown export error recovery suggestion"),
					NSUnderlyingErrorKey : writeErrors,
				};
				*errorRef = [NSError errorWithDomain:LLDumperDataErrorDomain code:LLDumperDataUnknownError userInfo:userInfo];
			}
			return nil;
		}];
		
		return;
	}
	
	[self setCompletionProvider:^ NSURL * (NSError **errorRef) {
		return resultingExportLocation;
	}];
}

@end
