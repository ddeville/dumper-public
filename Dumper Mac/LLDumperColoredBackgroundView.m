//
//  LLDumperColoredBackgroundView.m
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperColoredBackgroundView.h"

@implementation LLDumperColoredBackgroundView

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
	_backgroundColor = backgroundColor;
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	CGColorRef backgroundColor = [[self backgroundColor] CGColor];
	if (backgroundColor == NULL) {
		return;
	}
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetFillColorWithColor(context, backgroundColor);
	CGContextFillRect(context, dirtyRect);
}

@end
