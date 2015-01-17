//
//  LLDumperPreferencesWindowController.m
//  Dumper
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperPreferencesWindowController.h"

#import "LLDumperData/LLDumperData.h"

#import "LLDumperApplication.h"

static NSString * const LLDumperPreferencesWindowToolbarGeneralIdentifier = @"general";
static NSString * const LLDumperPreferencesWindowToolbarThemesIdentifier = @"themes";

@interface LLDumperPreferencesWindowController (/* Window */)

@property (strong, nonatomic) NSView *currentView;

@end

@interface LLDumperPreferencesWindowController (/* General */)

@property (assign, nonatomic) IBOutlet NSView *generalView;

@end

@interface LLDumperPreferencesWindowController (/* Themes */)

@property (assign, nonatomic) IBOutlet NSView *themesView;

@property (assign, nonatomic) IBOutlet NSTextView *textView;

- (IBAction)colorChanged:(id)sender;
- (IBAction)duplicateTheme:(id)sender;

@property (strong, nonatomic) IBOutlet NSArrayController *themeContentController;

@property (assign, getter = isSetup, nonatomic) BOOL setup;

@end

@implementation LLDumperPreferencesWindowController

static NSString *_LLDumperPreferencesWindowControllerThemeContentControllerSelectionObservationContext = @"_LLDumperPreferencesWindowControllerThemeContentControllerSelectionObservationContext";

- (id)init
{
	return [self initWithWindowNibName:@"LLDumperPreferencesWindow"];
}

- (void)dealloc
{
	[_themeContentController unbind:NSContentArrayBinding];
	[_themeContentController removeObserver:self forKeyPath:@"selection" context:&_LLDumperPreferencesWindowControllerThemeContentControllerSelectionObservationContext];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	if ([self isSetup]) {
		return;
	}
	
	[[self themeContentController] setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:LLDumperThemeNameKey ascending:YES]]];
	[[self themeContentController] bind:NSContentArrayBinding toObject:[self themeController] withKeyPath:LLDumperThemeControllerThemesKey options:nil];
	[[self themeContentController] addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:&_LLDumperPreferencesWindowControllerThemeContentControllerSelectionObservationContext];
	
	[self _configureWindowToView:[self generalView] identifier:LLDumperPreferencesWindowToolbarGeneralIdentifier animated:NO];
	
	[self setSetup:YES];
}

#pragma mark - Actions

- (IBAction)showGeneral:(id)sender
{
	[self showWindow:sender];
	
	[self _configureWindowToView:[self generalView] identifier:LLDumperPreferencesWindowToolbarGeneralIdentifier animated:YES];
}

- (IBAction)showThemes:(id)sender
{
	[self showWindow:sender];
	
	[[self themeContentController] setSelectedObjects:@[[[self themeController] currentTheme]]];
	[self _updateTextViewWithCurrentTheme];
	
	[self _configureWindowToView:[self themesView] identifier:LLDumperPreferencesWindowToolbarThemesIdentifier animated:YES];
}

#pragma mark - Actions (Themes)

- (IBAction)colorChanged:(id)sender
{
	NSDictionary *bindingInfo = [sender infoForBinding:NSValueBinding];
	
	id observedObject = bindingInfo[NSObservedObjectKey];
	id observedKeyPath = bindingInfo[NSObservedKeyPathKey];
	
	[observedObject setValue:[sender color] forKeyPath:observedKeyPath];
	
	[[self themeController] updateTheme:[[self themeController] currentTheme]];
	
	[self _updateTextViewWithCurrentTheme];
}

- (IBAction)duplicateTheme:(id)sender
{
	LLDumperTheme *selectedTheme = [[[self themeContentController] selectedObjects] firstObject];
	[[self themeController] duplicateTheme:selectedTheme];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &_LLDumperPreferencesWindowControllerThemeContentControllerSelectionObservationContext) {
		[[self themeController] setCurrentTheme:[[[self themeContentController] selectedObjects] firstObject]];
		
		[self _updateTextViewWithCurrentTheme];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Private (Transition)

- (void)_configureWindowToView:(NSView *)view identifier:(NSString *)identifier animated:(BOOL)animated
{
	NSView *previousView = [self currentView];
	NSView *nextView = view;
	
	if (nextView == nil || [nextView isEqual:previousView]) {
		return;
	}
	
	if (previousView == nil) {
		animated = NO;
	}
	
	[self _updateToolbarItemIdentifier:identifier];
	
	NSView *contentView = [[self window] contentView];
	[self setCurrentView:nextView];
	
	[previousView removeFromSuperview];
	
	CGRect nextViewFrame = {.size.width = fmax([nextView fittingSize].width, CGRectGetWidth([nextView frame])), .size.height = fmax([nextView fittingSize].height, CGRectGetHeight([nextView frame]))};
	[nextView setFrame:nextViewFrame];
	
	CGRect contentFrame = {.origin = [[self window] frame].origin, .size = nextViewFrame.size};
	contentFrame.origin.y += CGRectGetHeight([contentView bounds]) - CGRectGetHeight(nextViewFrame);
	
	CGRect windowFrame = [[self window] frameRectForContentRect:contentFrame];
	
	[[self window] setFrame:windowFrame display:YES animate:animated];
	[contentView addSubview:nextView];
}

- (void)_updateToolbarItemIdentifier:(NSString *)identifier
{
	[[[self window] toolbar] setSelectedItemIdentifier:identifier];
	
	[[[[self window] toolbar] items] enumerateObjectsUsingBlock:^ (NSToolbarItem *item, NSUInteger idx, BOOL *stop) {
		if ([[item itemIdentifier] isEqualToString:identifier]) {
			[[self window] setTitle:[item label]];
		}
	}];
}

#pragma mark - Private (Themes)

- (void)_updateTextViewWithCurrentTheme
{
	LLDumperTheme *theme = [[[self themeContentController] selectedObjects] firstObject];
	NSString *text = [[self textView] string];
	
	NSMutableAttributedString *syntaxHighlightedHeaderContents = [[LLDumperObjcHeaderSyntaxHighlighter syntaxHighlightedHeaderContent:text theme:theme] mutableCopy];
	[syntaxHighlightedHeaderContents addAttribute:NSFontAttributeName value:[[self textView] font] range:NSMakeRange(0, [syntaxHighlightedHeaderContents length])];
	[[[self textView] textStorage] setAttributedString:syntaxHighlightedHeaderContents];
	
	[[self textView] setBackgroundColor:[LLDumperObjcHeaderSyntaxHighlighter backgroundColorForTheme:theme]];
	[[self textView] setSelectedTextAttributes:[LLDumperObjcHeaderSyntaxHighlighter selectedTextAttributesForTheme:theme]];
}

#pragma mark - NSControlSubclassNotifications

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	NSString *name = [[notification object] stringValue];
	if ([name length] == 0) {
		name = NSLocalizedString(@"Untitled", @"LLDumperPreferencesWindowController untitle");
	}
	[[[self themeContentController] selection] setValue:name forKey:LLDumperThemeNameKey];
}

@end
