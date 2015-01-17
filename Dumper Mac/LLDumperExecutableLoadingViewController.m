//
//  LLDumperExecutableLoadingViewController.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperExecutableLoadingViewController.h"

#import "LLDumperDocument.h"

#import "LLDumperDropZoneView.h"

@interface LLDumperExecutableLoadingViewController () <LLDumperDropZoneViewDelegate>

@property (readwrite, assign, nonatomic) NSButton *dropzoneButton;

- (LLDumperDropZoneView *)view;

@end

@implementation LLDumperExecutableLoadingViewController

- (id)init
{
	return [self initWithNibName:@"LLDumperExecutableLoadingView" bundle:[NSBundle mainBundle]];
}

- (void)loadView
{
	[super loadView];
	
	[[self view] registerForDraggedTypes:@[(id)kUTTypeFileURL]];
}

- (LLDumperDropZoneView *)view
{
	return (id)[super view];
}

- (IBAction)chooseExecutable:(id)sender
{
	NSOpenPanel *openPanel = [LLDumperDocument importOpenPanel];
	[openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^ (NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) {
			return;
		}
		
		NSURL *openedURL = [openPanel URL];
		[self _processedExecutableAtLocation:openedURL];
	}];
}

- (void)_processedExecutableAtLocation:(NSURL *)executableLocation
{
	[[self delegate] executableLoadingViewController:self didChooseExecutableAtLocation:executableLocation];
}

- (void)_updateDropzoneImageStatus:(BOOL)dropping
{
	[[self dropzoneButton] highlight:dropping];
}

#pragma mark - LLDumperDropZoneViewDelegate

- (NSDragOperation)dropZoneView:(LLDumperDropZoneView *)dropZoneView draggingEntered:(id <NSDraggingInfo>)dropInfo
{
	if ([self isLoading]) {
		return NSDragOperationNone;
	}
	
	NSDictionary *options = @{
		NSPasteboardURLReadingFileURLsOnlyKey : @YES,
		NSPasteboardURLReadingContentsConformToTypesKey : [LLDumperDocument allowedImportFileTypes],
	};
	
	__block BOOL acceptedDrop = NO;
	
	[dropInfo enumerateDraggingItemsWithOptions:(NSDraggingItemEnumerationOptions)0 forView:[self view] classes:@[[NSURL class]] searchOptions:options usingBlock:^ (NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
		if ([[draggingItem item] isKindOfClass:[NSURL class]]) {
			acceptedDrop = YES;
			*stop = YES;
		}
	}];
	
	[self _updateDropzoneImageStatus:acceptedDrop];
	
	if (acceptedDrop) {
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (void)dropZoneView:(LLDumperDropZoneView *)dropZoneView draggingExited:(id <NSDraggingInfo>)dropInfo
{
	[self _updateDropzoneImageStatus:NO];
}

- (BOOL)dropZoneView:(LLDumperDropZoneView *)dropZoneView acceptDrop:(id <NSDraggingInfo>)dropInfo
{
	[self _updateDropzoneImageStatus:NO];
	
	NSDictionary *options = @{
		NSPasteboardURLReadingFileURLsOnlyKey : @YES,
		NSPasteboardURLReadingContentsConformToTypesKey : [LLDumperDocument allowedImportFileTypes],
	};
	
	__block NSMutableArray *droppedAssetURLs = [NSMutableArray array];
	
	[dropInfo enumerateDraggingItemsWithOptions:(NSDraggingItemEnumerationOptions)0 forView:[self view] classes:@[[NSURL class]] searchOptions:options usingBlock:^ (NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
		if ([[draggingItem item] isKindOfClass:[NSURL class]]) {
			[droppedAssetURLs addObject:[draggingItem item]];
		}
	}];
	
	if ([droppedAssetURLs count] == 0) {
		return NO;
	}
	
	[[self delegate] executableLoadingViewController:self didChooseExecutableAtLocation:[droppedAssetURLs lastObject]];
	
	return YES;
}

@end
