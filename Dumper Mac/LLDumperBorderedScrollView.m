//
//  LLDumperRecentDocumentsScrollView.m
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperBorderedScrollView.h"

@interface _LLDumperBorderView : NSView

@end

@implementation _LLDumperBorderView

- (void)drawRect:(NSRect)dirtyRect
{
	CGRect insetBounds = CGRectInset([self bounds], 0.5, 0.5);
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:insetBounds xRadius:4.0 yRadius:4.0];
	
	CGFloat backgroundGradientHeight = 2.5 / CGRectGetHeight(insetBounds);
	NSGradient *backgroundGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedWhite:0.4 alpha:0.15], 0.0, [NSColor clearColor], backgroundGradientHeight, nil];
	[backgroundGradient drawInBezierPath:path angle:270.0];
	
	[[NSColor colorWithCalibratedWhite:0.68 alpha:1.0] setStroke];
	[path stroke];
}

@end

#pragma mark -

@interface LLDumperBorderedScrollView ()

@property (strong, nonatomic) _LLDumperBorderView *borderView;

@end

@implementation LLDumperBorderedScrollView

- (void)tile
{
	[super tile];
	
	_LLDumperBorderView *borderView = [self borderView];
	if (borderView == nil) {
		borderView = [[_LLDumperBorderView alloc] initWithFrame:[self bounds]];
		[self addSubview:borderView];
		[self setBorderView:borderView];
		
		[[self contentView] setCopiesOnScroll:NO];
	}
	
	[borderView setFrame:[self bounds]];
	
	CGRect verticalScrollerFrame = [[self verticalScroller] frame];
	verticalScrollerFrame.size.height -= 2.0;
	verticalScrollerFrame.origin.y += 1.0;
	verticalScrollerFrame.origin.x -= 1.0;
	[[self verticalScroller] setFrame:verticalScrollerFrame];
}

@end

#pragma mark -

@implementation LLDumperRoundedTableRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	NSColor *color = [self isEmphasized] ? [NSColor alternateSelectedControlColor] : [NSColor secondarySelectedControlColor];
	[color setFill];
	
	CGRect frame = CGRectInset([self bounds], 3.0, 3.0);
	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:4.0 yRadius:4.0];
	
	[bezierPath fill];
}

@end
