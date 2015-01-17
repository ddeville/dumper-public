//
//  LLDumperData-Functions.m
//  Dumper Common
//
//  Created by Damien DeVille on 1/4/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import "LLDumperData-Functions.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#import "LLDumperData-Constants.h"

NSArray *LLDumperDocumentLocationsInDirectory(NSURL *location, BOOL skipsSubdirectoryDescendants)
{
	NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles);
	options |= (skipsSubdirectoryDescendants ? NSDirectoryEnumerationSkipsSubdirectoryDescendants : 0);
	
	NSDirectoryEnumerator *documentsDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:location includingPropertiesForKeys:@[NSURLTypeIdentifierKey] options:options errorHandler:^ BOOL (NSURL *url, NSError *error) {
		return YES;
	}];
	
	NSMutableArray *dumperDocuments = [NSMutableArray array];
	
	for (NSURL *itemURL in documentsDirectoryEnumerator) {
		NSNumber *directory = [itemURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:NULL][NSURLIsDirectoryKey];
		NSNumber *package = [itemURL resourceValuesForKeys:@[NSURLIsPackageKey] error:NULL][NSURLIsPackageKey];
		
		if ([directory boolValue] && ![package boolValue]) {
			continue;
		}
		
		NSString *fileType = [itemURL resourceValuesForKeys:@[NSURLTypeIdentifierKey] error:NULL][NSURLTypeIdentifierKey];
		
		if (!UTTypeConformsTo((__bridge CFStringRef)fileType, (__bridge CFStringRef)LLDumperDocumentFileType)) {
			continue;
		}
		
		[dumperDocuments addObject:itemURL];
	}
	
	return dumperDocuments;
}

static BOOL _LLDumperCoordinateMove(NSFileCoordinator *fileCoordinator, NSURL *originURL, NSURL *destinationURL, NSError **errorRef)
{
	__block BOOL moved = NO;
	
	[fileCoordinator coordinateReadingItemAtURL:originURL options:(NSFileCoordinatorReadingOptions)0 writingItemAtURL:destinationURL options:NSFileCoordinatorWritingForMoving error:errorRef byAccessor:^ (NSURL *coordinatedOriginURL, NSURL *coordinatedDestinationURL) {
		moved = [[NSFileManager defaultManager] moveItemAtURL:coordinatedOriginURL toURL:coordinatedDestinationURL error:errorRef];
	}];
	
	return moved;
}

BOOL LLDumperCoordinateMoveItemAvoidingNameConflicts(NSURL *originURL, NSURL *destinationURL, NSError **errorRef)
{
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	
	NSURL *baseDestinationURL = [destinationURL URLByDeletingLastPathComponent];
	
	NSString *baseFilename = [[destinationURL lastPathComponent] stringByDeletingPathExtension];
	NSString *extension = [destinationURL pathExtension];
	NSUInteger fileNumber = 2;
	
	BOOL moved = NO;
	NSURL *currentDestinationURL = [[baseDestinationURL URLByAppendingPathComponent:baseFilename] URLByAppendingPathExtension:extension];
	
	do {
		NSError *error = nil;
		moved = _LLDumperCoordinateMove(fileCoordinator, originURL, currentDestinationURL, &error);
		
		if (moved) {
			break;
		}
		
		if (![[error domain] isEqualToString:NSCocoaErrorDomain] || [error code] != NSFileWriteFileExistsError) {
			if (errorRef != NULL) {
				*errorRef = error;
			}
			break;
		}
		
		NSString *updatedFilename = [baseFilename stringByAppendingFormat:@" %lu", (unsigned long)fileNumber];
		currentDestinationURL = [[baseDestinationURL URLByAppendingPathComponent:updatedFilename] URLByAppendingPathExtension:extension];
		
		fileNumber++;
	}
	while (YES);
	
	return moved;
}
