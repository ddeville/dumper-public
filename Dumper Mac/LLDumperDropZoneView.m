//
//  LLDumperDropZoneView.m
//  Dumper
//
//  Created by Damien DeVille on 8/2/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDropZoneView.h"

@interface LLDumperDropZoneView ()

@property (strong, nonatomic) NSGradient *backgroundGradient;

@end

@implementation LLDumperDropZoneView

static void _LLDumperCommonInit(LLDumperDropZoneView *self)
{
	NSColor *startingColor = [NSColor colorWithCalibratedWhite:(225.0 / 255.0) alpha:1.0];
	NSColor *endingColor = [NSColor colorWithCalibratedWhite:(245.0 / 255.0) alpha:1.0];
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	
	self->_backgroundGradient = gradient;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self == nil) {
		return nil;
	}
	_LLDumperCommonInit(self);
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self == nil) {
		return nil;
	}
	_LLDumperCommonInit(self);
	return self;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	[[self backgroundGradient] drawInRect:[self frame] angle:90.0];
}

#pragma mark - Dragging

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([[self delegate] respondsToSelector:@selector(dropZoneView:draggingEntered:)]) {
		return [[self delegate] dropZoneView:self draggingEntered:sender];
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	if ([[self delegate] respondsToSelector:@selector(dropZoneView:draggingExited:)]) {
		[[self delegate] dropZoneView:self draggingExited:sender];
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if ([[self delegate] respondsToSelector:@selector(dropZoneView:acceptDrop:)]) {
		return [[self delegate] dropZoneView:self acceptDrop:sender];
	}
	return NO;
}

@end
