//
//  LLDumperClassListViewController.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperHeaderListViewController.h"

#import "LLDumperDocument.h"

#import "LLDumperTableView.h"

NSString * const LLDumperHeaderListViewControllerSelectedHeaderFilename = @"selectedHeaderFilename";

@interface LLDumperHeaderListViewController ()

@property (readwrite, assign, nonatomic) NSTableView *headersTableView;
@property (readwrite, assign, nonatomic) NSArrayController *headersArrayController;
@property (readwrite, assign, nonatomic) NSSearchField *searchField;
@property (readwrite, assign, nonatomic) NSMenu *contextualMenu;

@property (assign, getter = isViewLoaded, nonatomic) BOOL viewLoaded;

@end

@implementation LLDumperHeaderListViewController

static NSString *_LLDumperHeadersArrayControllerSelectedObjectsObservationContext = @"_LLDumperHeadersArrayControllerSelectedObjectsObservationContext";

@synthesize viewLoaded = _viewLoaded;

- (id)init
{
	return [self initWithNibName:@"LLDumperHeaderListView" bundle:[NSBundle mainBundle]];
}

- (void)dealloc
{
	if (!_viewLoaded) {
		return;
	}
	
	[_headersArrayController removeObserver:self forKeyPath:@"selectedObjects" context:&_LLDumperHeadersArrayControllerSelectedObjectsObservationContext];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
	[[self headersArrayController] setSortDescriptors:@[sortDescriptor]];
	
	[[self headersTableView] setTarget:self];
	[[self headersTableView] setDoubleAction:@selector(openHeaderInExternalEditor:)];
}

- (void)loadView
{
	[super loadView];
	
	[[self headersArrayController] addObserver:self forKeyPath:@"selectedObjects" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:&_LLDumperHeadersArrayControllerSelectedObjectsObservationContext];
	
	[self setViewLoaded:YES];
}

#pragma mark - Properties

- (void)setSelectedHeaderFilename:(NSString *)selectedHeaderFilename
{
	_selectedHeaderFilename = [selectedHeaderFilename copy];
	
	if (selectedHeaderFilename == nil) {
		return;
	}
	
	NSString *currentSelectedHeaderFilename = [[[self headersArrayController] selectedObjects] firstObject];
	if ([currentSelectedHeaderFilename isEqualToString:selectedHeaderFilename]) {
		return;
	}
	
	[[self headersArrayController] setSelectedObjects:@[selectedHeaderFilename]];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &_LLDumperHeadersArrayControllerSelectedObjectsObservationContext) {
		[self setSelectedHeaderFilename:[[[self headersArrayController] selectedObjects] lastObject]];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Actions

- (IBAction)openHeaderInExternalEditor:(id)sender
{
	NSInteger selectedRow = [[self headersTableView] selectedRow];
	if (selectedRow == -1) {
		return;
	}
	
	NSString *headerFilename = [[self headersArrayController] arrangedObjects][selectedRow];
	NSString *headerContents = [[self document] headerContentWithFilename:headerFilename];
	
	NSURL *temporaryLocation = [[self _temporaryDirectory] URLByAppendingPathComponent:headerFilename];
	
	BOOL copied = [headerContents writeToURL:temporaryLocation atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	if (!copied) {
		return;
	}
	
	[[NSWorkspace sharedWorkspace] openURL:temporaryLocation];
}

#pragma mark - Private

- (NSURL *)_temporaryDirectory
{
	static NSString * const LLDumperTemporaryDirectoryName = @"Dumper";
	
	NSURL *temporaryDirectory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:LLDumperTemporaryDirectoryName isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
	
	return temporaryDirectory;
}

#pragma mark - NSTableViewDelegate

- (NSMenu *)tableView:(NSTableView *)tableView contextMenuForRow:(NSInteger)row
{
	return [self contextualMenu];
}

- (void)tableView:(NSTableView *)tableView contextMenuDidCloseForRow:(NSInteger)row
{
	// nop
}

@end
