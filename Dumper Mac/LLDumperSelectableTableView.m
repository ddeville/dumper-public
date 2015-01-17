//
//  LLDumperSelectableTableView.m
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperSelectableTableView.h"

@implementation LLDumperSelectableTableView

- (void)setDelegate:(id <LLDumperSelectableTableViewDelegate>)delegate
{
	[super setDelegate:delegate];
}

- (id <LLDumperSelectableTableViewDelegate>)delegate
{
	return (id <LLDumperSelectableTableViewDelegate>)[super delegate];
}

- (void)keyDown:(NSEvent *)event
{
	if (![[self delegate] respondsToSelector:@selector(selectableTableView:keyDown:)]) {
		[super keyDown:event];
		return;
	}
	
	NSEvent *delegateEvent = [[self delegate] selectableTableView:self keyDown:event];
	if (delegateEvent != nil) {
		[super keyDown:delegateEvent];
	}
}

@end
