//
//  LLDumperDocumentStorage.m
//  Dumper Common
//
//  Created by Damien DeVille on 12/17/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDocumentStorage.h"

#import "LLDumperData-Constants.h"

static NSString * const LLDumperDocumentStorageInfoFileWrapperFilename = @"Info.plist";
static NSString * const LLDumperDocumentStorageHeadersFileWrapperFilename = @"Headers.plist";

@interface LLDumperDocumentStorage ()

@property (copy, nonatomic) NSString *fileType;
@property (strong, nonatomic) NSFileWrapper *fileWrapper;

@property (readwrite, strong, nonatomic) NSArray *sortedHeaderFilenames;

@end

@implementation LLDumperDocumentStorage

- (id)initWithFileType:(NSString *)fileType
{
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	_fileType = [fileType copy];
	
	return self;
}

- (void)setHeaders:(NSDictionary *)headers
{
	_headers = headers;
	
	[self setSortedHeaderFilenames:[[headers allKeys] sortedArrayUsingSelector:@selector(compare:)]];
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)errorRef
{
	NSParameterAssert([typeName isEqualToString:[self fileType]]);
	
	if ([self fileWrapper] == nil) {
		NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
		[self setFileWrapper:fileWrapper];
	}
	
	NSFileWrapper *fileWrapper = [self fileWrapper];
	
	if ([self info] == nil) {
		[self setInfo:[self _createDefaultInfo]];
	}
	
	BOOL infoEncoded = [self _encodeContents:[self info] fileWrapper:fileWrapper filename:LLDumperDocumentStorageInfoFileWrapperFilename error:errorRef];
	if (!infoEncoded) {
		return nil;
	}
	
	BOOL headersEncoded = [self _encodeContents:[self headers] fileWrapper:fileWrapper filename:LLDumperDocumentStorageHeadersFileWrapperFilename error:errorRef];
	if (!headersEncoded) {
		return nil;
	}
	
	return fileWrapper;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)errorRef
{
	if (![contents isKindOfClass:[NSFileWrapper class]] || ![typeName isEqualToString:[self fileType]]) {
		if (errorRef != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"The document is not a valid Dumper document", nil, [NSBundle bundleWithIdentifier:LLDumperDataBundleIdentifier], @"LLDumperDocumentStorage invalid dumper document."),
			};
			*errorRef = [NSError errorWithDomain:LLDumperDataErrorDomain code:LLDumperDataUnknownError userInfo:userInfo];
		}
		return NO;
	}
	
	[self setFileWrapper:contents];
	
	NSDictionary *info = [self _decodeContents:contents filename:LLDumperDocumentStorageInfoFileWrapperFilename error:errorRef];
	if (info == nil) {
		return NO;
	}
	[self setInfo:info];
	
	NSDictionary *headers = [self _decodeContents:contents filename:LLDumperDocumentStorageHeadersFileWrapperFilename error:errorRef];
	if (headers == nil) {
		return NO;
	}
	[self setHeaders:headers];
	
	return YES;
}

#pragma mark - Private

- (BOOL)_encodeContents:(NSDictionary *)contents fileWrapper:(NSFileWrapper *)fileWrapper filename:(NSString *)filename error:(NSError **)errorRef
{
	if (contents == nil) {
		return YES;
	}
	
	NSData *data = [NSPropertyListSerialization dataWithPropertyList:contents format:NSPropertyListXMLFormat_v1_0 options:(NSPropertyListWriteOptions)0 error:errorRef];
	if (data == nil) {
		return NO;
	}
	
	NSFileWrapper *dataFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
	[dataFileWrapper setPreferredFilename:filename];
	[fileWrapper removeFileWrapper:[fileWrapper fileWrappers][filename]];
	[fileWrapper addFileWrapper:dataFileWrapper];
	
	return YES;
}

- (NSDictionary *)_decodeContents:(NSFileWrapper *)fileWrapper filename:(NSString *)filename error:(NSError **)errorRef
{
	NSFileWrapper *dataFileWrapper = [fileWrapper fileWrappers][filename];
	if (dataFileWrapper == nil) {
		return @{};
	}
	
	NSData *data = [dataFileWrapper regularFileContents];
	
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	NSDictionary *contents = [NSPropertyListSerialization propertyListWithData:data options:(NSPropertyListReadOptions)0 format:&format error:errorRef];
	if (contents == nil) {
		return nil;
	}
	
	return contents;
}

- (NSDictionary *)_createDefaultInfo
{
	return @{
		LLDumperDocumentStorageInfoVersionKey : @1,
		LLDumperDocumentStorageInfoCreationDateKey : [NSDate date],
	};
}

@end

NSString * const LLDumperDocumentStorageInfoVersionKey = @"version";
NSString * const LLDumperDocumentStorageInfoCreationDateKey = @"creationDate";
