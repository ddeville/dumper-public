//
//  LLDumperWelcomeWindowController.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperWelcomeWindowController.h"

#import <Carbon/Carbon.h>

#import "LLDumperDocument.h"
#import "LLDumperRecentDocument.h"

#import "LLDumperColoredBackgroundView.h"
#import "LLDumperBorderedScrollView.h"
#import "LLDumperSelectableTableView.h"

#import "Dumper-Constants.h"

@interface LLDumperWelcomeWindowController ()

@property (assign, nonatomic) IBOutlet LLDumperColoredBackgroundView *contentView;
@property (assign, nonatomic) IBOutlet LLDumperColoredBackgroundView *separatorView;
@property (assign, nonatomic) IBOutlet LLDumperColoredBackgroundView *buttonsView;

@property (readwrite, assign, nonatomic) NSTableView *recentDocumentsTableView;
@property (readwrite, assign, nonatomic) NSArrayController *recentDocumentsArrayController;

@end

@implementation LLDumperWelcomeWindowController

- (id)init
{
	return [self initWithWindowNibName:@"LLDumperWelcomeWindow"];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[[self window] setExcludedFromWindowsMenu:YES];
	[[self window] setTitle:NSLocalizedString(@"Welcome to Dumper", @"LLDumperWelcomeWindowController title")];
	
	[self _setupViews];
	[self _refreshContents];
}

- (void)showWindow:(id)sender
{
	[self _refreshContents];
	
	[super showWindow:sender];
}

#pragma mark - Private

- (void)_setupViews
{
	[[self contentView] setBackgroundColor:[NSColor colorWithWhite:0.95 alpha:1.0]];
	[[self separatorView] setBackgroundColor:[NSColor colorWithCalibratedWhite:(160.0 / 255.0) alpha:1.0]];
	[[self buttonsView] setBackgroundColor:[NSColor colorWithCalibratedWhite:(234.0 / 255.0) alpha:1.0]];
	
	[[self recentDocumentsTableView] setTarget:self];
	[[self recentDocumentsTableView] setDoubleAction:@selector(openRecentDocument:)];
}

- (void)_refreshContents
{
	NSArray *recentDocumentURLs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	[self _prepareControllerWithRecentDocuments:recentDocumentURLs];
}

#pragma mark - Actions

- (void)openRecentDocument:(id)sender
{
	NSInteger selectedRow = [[self recentDocumentsTableView] selectedRow];
	if (selectedRow == -1) {
		return;
	}
	
	LLDumperRecentDocument *recentDocument = [[self recentDocumentsArrayController] arrangedObjects][selectedRow];
	
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[recentDocument URL] display:YES completionHandler:^ (NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
		if (document != nil && !documentWasAlreadyOpen) {
			[self close];
		}
	}];
}

- (IBAction)viewFrameworks:(id)sender
{
	NSString *systemLibraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES) lastObject];
	NSString *systemFrameworkDirectory = [systemLibraryDirectory stringByAppendingPathComponent:@"Frameworks"];
	[self _presentOpenPanelForDirectoryURL:[NSURL fileURLWithPath:systemFrameworkDirectory]];
}

- (IBAction)viewApplications:(id)sender
{
	NSString *applicationsDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES) lastObject];
	[self _presentOpenPanelForDirectoryURL:[NSURL fileURLWithPath:applicationsDirectory]];
}

- (void)_presentOpenPanelForDirectoryURL:(NSURL *)directoryURL
{
	NSOpenPanel *openPanel = [LLDumperDocument importOpenPanel];
	[openPanel setDirectoryURL:directoryURL];
	
	[openPanel beginSheetModalForWindow:[self window] completionHandler:^ (NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) {
			return;
		}
		
		NSURL *openedURL = [openPanel URL];
		
		LLDumperDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:NULL];
		[document extractHeadersInExectuableAtLocation:openedURL];
		
		[[self window] close];
	}];
}

#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	static NSString * const LLDumperRoundedTableRowViewIdentifier = @"LLDumperRoundedTableRowViewIdentifier";
	
	LLDumperRoundedTableRowView *tableRowView = [tableView makeViewWithIdentifier:LLDumperRoundedTableRowViewIdentifier owner:nil];
	if (tableRowView == nil) {
		tableRowView = [[LLDumperRoundedTableRowView alloc] initWithFrame:CGRectZero];
		[tableRowView setIdentifier:LLDumperRoundedTableRowViewIdentifier];
	}
	return tableRowView;
}

- (NSEvent *)selectableTableView:(LLDumperSelectableTableView *)table keyDown:(NSEvent *)event
{
	if ([event keyCode] == kVK_Return) {
		[self openRecentDocument:event];
		return nil;
	}
	return event;
}

#pragma mark - Private

- (void)_prepareControllerWithRecentDocuments:(NSArray *)documentURLs
{
	NSMutableArray *recentDocuments = [NSMutableArray array];
	
	[documentURLs enumerateObjectsUsingBlock:^ (NSURL *documentURL, NSUInteger idx, BOOL *stop) {
		LLDumperRecentDocument *recentDocument = [[LLDumperRecentDocument alloc] init];
		[recentDocument setURL:documentURL];
		[recentDocument setFilename:[documentURL lastPathComponent]];
		[recentDocuments addObject:recentDocument];
	}];
	
	[[self recentDocumentsArrayController] setContent:recentDocuments];
}

@end
