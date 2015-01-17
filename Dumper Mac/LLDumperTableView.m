//
//  LLDumperTableView.m
//  Dumper
//
//  Created by Damien DeVille on 8/2/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperTableView.h"

@interface LLDumperTableView ()

@property (assign, nonatomic) NSInteger contextualClickedRow;

@end

@implementation LLDumperTableView

@dynamic delegate;

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	NSInteger row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
	
	NSMenu *menu = [self contextMenuForRow:row];
	if (menu == nil) {
		return nil;
	}
	
	[menu setDelegate:self];
	
	[self setContextualClickedRow:row];
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	
	return menu;
}

- (void)menuDidClose:(NSMenu *)menu
{
	if ([[self delegate] respondsToSelector:@selector(tableView:contextMenuDidCloseForRow:)]) {
		[[self delegate] tableView:self contextMenuDidCloseForRow:[self contextualClickedRow]];
	}
}

- (NSMenu *)contextMenuForRow:(NSInteger)row
{
	if ([[self delegate] respondsToSelector:@selector(tableView:contextMenuForRow:)]) {
		return [[self delegate] tableView:self contextMenuForRow:row];
	}
	return nil;
}

@end
