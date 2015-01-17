//
//  LLDumperClassDetailsViewController.m
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperHeaderDetailsViewController.h"

#import "LLDumperData/LLDumperData.h"

#import "LLDumperApplication.h"

#import "Dumper-Defaults.h"

@interface LLDumperHeaderDetailsViewController ()

@property (readwrite, assign, nonatomic) NSTextView *textView;

@property (assign, getter = isViewLoaded, nonatomic) BOOL viewLoaded;

@end

@implementation LLDumperHeaderDetailsViewController

static NSString *_LLDumperHeaderDetailsViewControllerThemeControllerCurrentThemeObservationContext = @"_LLDumperHeaderDetailsViewControllerThemeControllerCurrentThemeObservationContext";
static NSString *_LLDumperHeaderDetailsViewControllerEditorLineWrappingDefaultObservationContext = @"_LLDumperHeaderDetailsViewControllerEditorLineWrappingDefaultObservationContext";

@synthesize viewLoaded = _viewLoaded;

+ (void)load
{
	@autoreleasepool {
		NSDictionary *defaults = @{LLDumperEditorLineWrappingDefault : @YES};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
}

- (id)init
{
	return [self initWithNibName:@"LLDumperHeaderDetailsView" bundle:[NSBundle mainBundle]];
}

- (void)loadView
{
	[super loadView];
	
	[[self textView] setFont:[self _codeFont]];
	[[self textView] setTextContainerInset:CGSizeMake(5.0, 5.0)];
	[[self textView] setHorizontallyResizable:YES];
	
	[[[self textView] enclosingScrollView] setHasHorizontalScroller:YES];
	
	[[[LLDumperApplication sharedApplication] themeController] addObserver:self forKeyPath:LLDumperThemeControllerCurrentThemeKey options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:&_LLDumperHeaderDetailsViewControllerThemeControllerCurrentThemeObservationContext];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.editorLineWrapping" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:&_LLDumperHeaderDetailsViewControllerEditorLineWrappingDefaultObservationContext];
	
	[self setViewLoaded:YES];
}

- (void)dealloc
{
	if (!_viewLoaded) {
		return;
	}
	
	[[[LLDumperApplication sharedApplication] themeController] removeObserver:self forKeyPath:LLDumperThemeControllerCurrentThemeKey context:&_LLDumperHeaderDetailsViewControllerThemeControllerCurrentThemeObservationContext];
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.editorLineWrapping" context:&_LLDumperHeaderDetailsViewControllerEditorLineWrappingDefaultObservationContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &_LLDumperHeaderDetailsViewControllerThemeControllerCurrentThemeObservationContext) {
		LLDumperTheme *currentTheme = change[NSKeyValueChangeNewKey];
		[self _updateColorTheme:currentTheme];
	}
	else if (context == &_LLDumperHeaderDetailsViewControllerEditorLineWrappingDefaultObservationContext) {
		LLDumperTheme *currentTheme = [[[LLDumperApplication sharedApplication] themeController] currentTheme];
		BOOL lineWrapping = [[NSUserDefaults standardUserDefaults] boolForKey:LLDumperEditorLineWrappingDefault];
		[self _updateTextWithLineWrapping:lineWrapping theme:currentTheme];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)updateText:(NSString *)text
{
	LLDumperTheme *theme = [[[LLDumperApplication sharedApplication] themeController] currentTheme];
	BOOL lineWrapping = [[NSUserDefaults standardUserDefaults] boolForKey:LLDumperEditorLineWrappingDefault];
	
	[[self textView] setString:@""];
	
	[self _updateTextViewBackgroundWithTheme:theme];
	[self _updateTextViewText:text theme:theme];
	[self _updateTextWithLineWrapping:lineWrapping theme:theme];
	
	[[self textView] scrollToBeginningOfDocument:nil];
}

- (void)_updateColorTheme:(LLDumperTheme *)theme
{
	[self _updateTextViewBackgroundWithTheme:theme];
	[self _updateTextViewText:[[self textView] string] theme:theme];
}

- (void)_updateTextViewText:(NSString *)text theme:(LLDumperTheme *)theme
{
	NSMutableAttributedString *syntaxHighlightedHeaderContents = [[LLDumperObjcHeaderSyntaxHighlighter syntaxHighlightedHeaderContent:text theme:theme] mutableCopy];
	[syntaxHighlightedHeaderContents addAttribute:NSFontAttributeName value:[self _codeFont] range:NSMakeRange(0, [syntaxHighlightedHeaderContents length])];
	
	[[[self textView] textStorage] setAttributedString:syntaxHighlightedHeaderContents];
}

- (void)_updateTextViewBackgroundWithTheme:(LLDumperTheme *)theme
{
	[[self textView] setBackgroundColor:[LLDumperObjcHeaderSyntaxHighlighter backgroundColorForTheme:theme]];
	[[self textView] setSelectedTextAttributes:[LLDumperObjcHeaderSyntaxHighlighter selectedTextAttributesForTheme:theme]];
}

- (void)_updateTextWithLineWrapping:(BOOL)lineWrapping theme:(LLDumperTheme *)theme
{
	CGFloat width = lineWrapping ? CGRectGetWidth([[[self textView] enclosingScrollView] bounds]) - 2.0 * [[self textView] textContainerInset].width : CGFLOAT_MAX;
	
	[[[self textView] enclosingScrollView] setHasHorizontalScroller:!lineWrapping];
	
	[[[self textView] textContainer] setContainerSize:CGSizeMake(width, CGFLOAT_MAX)];
	[[[self textView] textContainer] setWidthTracksTextView:lineWrapping];
	
	[self _updateTextViewText:[[self textView] string] theme:theme];
}

- (NSFont *)_codeFont
{
	return [NSFont fontWithName:@"Menlo-Regular" size:12.0];
}

@end
