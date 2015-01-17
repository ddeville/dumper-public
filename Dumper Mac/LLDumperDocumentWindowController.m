//
//  LLDumperDocumentWindowController.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDocumentWindowController.h"
#import "LLDumperDocumentWindowController+Private.h"

#import "LLDumperData/LLDumperData.h"

#import "LLDumperExecutableLoadingViewController.h"
#import "LLDumperHeaderListViewController.h"
#import "LLDumperHeaderDetailsViewController.h"

#import "LLDumperDocument.h"
#import "LLDumperDocument+Private.h"

#import "Dumper-Constants.h"

typedef NS_ENUM(NSInteger, LLDumperDocumentWindowControllerState) {
	LLDumperDocumentWindowControllerStateUnknown = 0,
	LLDumperDocumentWindowControllerStateSelection = 1,
	LLDumperDocumentWindowControllerStateBrowsing = 2,
};

@interface LLDumperDocumentWindowController (/* User Interface */)

@property (strong, nonatomic) NSArray *contentViewConstraints;

@property (readwrite, assign, nonatomic) LLDumperExecutableLoadingViewController *executableLoadingViewController;
@property (readwrite, assign, nonatomic) NSView *executableLoadingContentView;

@property (readwrite, assign, nonatomic) NSSplitView *headerSplitView;

@property (readwrite, assign, nonatomic) LLDumperHeaderListViewController *headersListViewController;
@property (readwrite, assign, nonatomic) NSView *headersListContentView;

@property (readwrite, assign, nonatomic) LLDumperHeaderDetailsViewController *headerDetailsViewController;
@property (readwrite, assign, nonatomic) NSView *headerDetailsContentView;

@end

@interface LLDumperDocumentWindowController ()

@property (assign, nonatomic) LLDumperDocumentWindowControllerState currentState;

@end

@implementation LLDumperDocumentWindowController

static NSString * _LLDumperDocumentWindowControllerHeaderListSelectedHeaderFilenameObservationContext = @"_LLDumperDocumentWindowControllerHeaderListSelectedHeaderFilenameObservationContext";

- (id)init
{
	return [self initWithWindowNibName:@"LLDumperDocumentWindow"];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	NSView *executableLoadingView = [[self executableLoadingViewController] view];
	[[self executableLoadingContentView] addSubview:executableLoadingView];
	[[self executableLoadingContentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[executableLoadingView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(executableLoadingView)]];
	[[self executableLoadingContentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[executableLoadingView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(executableLoadingView)]];
	
	NSView *headersListView = [[self headersListViewController] view];
	[[self headersListContentView] addSubview:headersListView];
	[[self headersListContentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headersListView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(headersListView)]];
	[[self headersListContentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headersListView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(headersListView)]];
	
	NSView *headerDetailsView = [[self headerDetailsViewController] view];
	[[self headerDetailsContentView] addSubview:headerDetailsView];
	[[self headerDetailsContentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerDetailsView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(headerDetailsView)]];
	[[self headerDetailsContentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerDetailsView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(headerDetailsView)]];
	
	[[[self headerDetailsViewController] textView] setNextKeyView:[[self headersListViewController] searchField]];
	[[[self headersListViewController] searchField] setNextKeyView:[[self headersListViewController] headersTableView]];
	[[[self headersListViewController] headersTableView] setNextKeyView:[[self headerDetailsViewController] textView]];
	
	[[self headersListViewController] addObserver:self forKeyPath:LLDumperHeaderListViewControllerSelectedHeaderFilename options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:&_LLDumperDocumentWindowControllerHeaderListSelectedHeaderFilenameObservationContext];
	
	[self _loadHeadersViewControllersWithDocument:[self document]];
	
	BOOL documentHasContents = ([[[self document] headerFilenames] count] > 0);
	[self setCurrentState:(documentHasContents ? LLDumperDocumentWindowControllerStateBrowsing : LLDumperDocumentWindowControllerStateSelection)];
	
	if (documentHasContents) {
		[self _setupFirstResponderForLoadedDocument];
	}
}

- (void)dealloc
{
	if (![self isWindowLoaded]) {
		return;
	}
	
	[_headersListViewController removeObserver:self forKeyPath:LLDumperHeaderListViewControllerSelectedHeaderFilename context:&_LLDumperDocumentWindowControllerHeaderListSelectedHeaderFilenameObservationContext];
}

- (void)setCurrentState:(LLDumperDocumentWindowControllerState)state
{
	LLDumperDocumentWindowControllerState currentState = _currentState;
	if (currentState == state) {
		return;
	}
	
	_currentState = state;
	
	[self _transitionFromState:currentState toState:state];
}

#pragma mark - Public

- (LLDumperDocument *)document
{
	return [super document];
}

#pragma mark - Actions

- (IBAction)performFindPanelAction:(id)sender
{
	[[self window] makeFirstResponder:[[self headersListViewController] searchField]];
}

- (IBAction)exportHeaders:(id)sender
{
	NSSavePanel *savePanel = [[NSSavePanel alloc] init];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setNameFieldStringValue:[[[[self document] fileURL] lastPathComponent] stringByDeletingPathExtension]];
	
	[savePanel beginSheetModalForWindow:[self window] completionHandler:^ (NSInteger result) {
		if (result == NSFileHandlingPanelCancelButton) {
			return;
		}
		[self _exportHeadersToLocation:[savePanel URL]];
	}];
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(exportHeaders:)) {
		return ([self currentState] == LLDumperDocumentWindowControllerStateBrowsing) && ([[[self document] headerFilenames] count] > 0);
	}
	else if ([menuItem action] == @selector(performFindPanelAction:)) {
		return ([self currentState] == LLDumperDocumentWindowControllerStateBrowsing);
	}
	return [super validateMenuItem:menuItem];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &_LLDumperDocumentWindowControllerHeaderListSelectedHeaderFilenameObservationContext) {
		NSString *selectedHeaderFilename = [[self headersListViewController] selectedHeaderFilename];
		[self _updateDetailsViewWithHeaderFilename:selectedHeaderFilename];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Restoration

static NSString * const _LLDumperDocumentWindowControllerSelectedHeaderFilenameRestorationKey = @"_LLDumperDocumentWindowControllerSelectedHeaderFilenameRestorationKey";

- (void)window:(NSWindow *)window willEncodeRestorableState:(NSCoder *)encoder
{
	NSString *selectedHeaderFilename = [[self headersListViewController] selectedHeaderFilename];
	if (selectedHeaderFilename != nil) {
		[encoder encodeObject:[[self headersListViewController] selectedHeaderFilename] forKey:_LLDumperDocumentWindowControllerSelectedHeaderFilenameRestorationKey];
	}
}

- (void)window:(NSWindow *)window didDecodeRestorableState:(NSCoder *)decoder
{
	NSString *selectedHeaderFilename = [decoder decodeObjectForKey:_LLDumperDocumentWindowControllerSelectedHeaderFilenameRestorationKey];
	if (selectedHeaderFilename != nil) {
		[[self headersListViewController] setSelectedHeaderFilename:selectedHeaderFilename];
	}
}

#pragma mark - NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return 180.0;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return 420.0;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
	return (view == [[splitView subviews] lastObject]);
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[splitView adjustSubviews];
	
	NSView *subview1 = [[splitView subviews] firstObject];
	NSView *subview2 = [[splitView subviews] lastObject];
	
	CGRect subview1Frame = [subview1 frame];
	CGRect subview2Frame = [subview2 frame];
	
	[subview1 setFrame:CGRectIntegral(subview1Frame)];
	[subview2 setFrame:CGRectIntegral(subview2Frame)];
}

#pragma mark - Private

- (void)_transitionFromState:(LLDumperDocumentWindowControllerState)currentState toState:(LLDumperDocumentWindowControllerState)nextState
{
	NSView *currentView = [self _viewForState:currentState];
	NSView *nextView = [self _viewForState:nextState];
	
	NSView *contentView = [[self window] contentView];
	
	[currentView removeFromSuperview];
	[contentView addSubview:nextView];
	
	NSArray *currentViewConstraints = [self contentViewConstraints] ? : @[];
	
	NSMutableArray *nextViewConstraints = [NSMutableArray array];
	[nextViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[nextView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(nextView)]];
	[nextViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[nextView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(nextView)]];
	[self setContentViewConstraints:nextViewConstraints];
	
	[contentView removeConstraints:currentViewConstraints];
	[contentView addConstraints:nextViewConstraints];
}

- (NSView *)_viewForState:(LLDumperDocumentWindowControllerState)state
{
	switch (state) {
		case LLDumperDocumentWindowControllerStateSelection:
			return [self executableLoadingContentView];
		case LLDumperDocumentWindowControllerStateBrowsing:
			return [self headerSplitView];
		case LLDumperDocumentWindowControllerStateUnknown:
		default:
			return nil;
	}
}

- (void)_prepareInterfaceForExtractingHeadersInExecutableAtLocation:(NSURL *)executableLocation
{
	[self setCurrentState:LLDumperDocumentWindowControllerStateSelection];
	[[self executableLoadingViewController] setLoading:YES];
	
	[[self document] _extractHeadersInExectuableAtLocation:executableLocation completion:^ (BOOL success, NSError *error) {
		[[self executableLoadingViewController] setLoading:NO];
		
		if (!success) {
			[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
			return;
		}
		
		[self _loadHeadersViewControllersWithDocument:[self document]];
		[self setCurrentState:LLDumperDocumentWindowControllerStateBrowsing];
		
		[self _setupFirstResponderForLoadedDocument];
	}];
}

- (void)_loadHeadersViewControllersWithDocument:(LLDumperDocument *)document
{
	[[self headersListViewController] setDocument:document];
	[[[self headersListViewController] headersArrayController] setContent:[document headerFilenames]];
}

- (void)_updateDetailsViewWithHeaderFilename:(NSString *)filename
{
	void (^updateText)(NSString *) = ^ void (NSString *text) {
		[[self headerDetailsViewController] updateText:text];
	};
	
	if (filename == nil) {
		updateText(@"");
		return;
	}
	
	NSString *headerContent = [[self document] headerContentWithFilename:filename];
	updateText(headerContent);
}

- (void)_exportHeadersToLocation:(NSURL *)location
{
	NSOperationQueue *exportOperationQueue = [[NSOperationQueue alloc] init];
	
	LLDumperDocumentHeadersExportOperation *exportOperation = [[LLDumperDocumentHeadersExportOperation alloc] initWithHeaders:[[self document] headers] exportLocation:location];
	[exportOperationQueue addOperation:exportOperation];
	
	NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^ {
		NSError *exportError = nil;
		NSURL *exportLocation = [exportOperation completionProvider](&exportError);
		
		if (exportLocation == nil) {
			[self presentError:exportError modalForWindow:[self window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
		}
	}];
	[completionOperation addDependency:exportOperation];
	[[NSOperationQueue mainQueue] addOperation:completionOperation];
}

- (void)_setupFirstResponderForLoadedDocument
{
	[[self window] makeFirstResponder:[[self headersListViewController] headersTableView]];
}

#pragma mark - LLDumperExecutableLoadingViewControllerDelegate

- (void)executableLoadingViewController:(LLDumperExecutableLoadingViewController *)executableLoadingViewController didChooseExecutableAtLocation:(NSURL *)executableLocation
{
	[self _prepareInterfaceForExtractingHeadersInExecutableAtLocation:executableLocation];
}

@end
