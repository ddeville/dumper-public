//
//  LLDumperSelectableTableView.h
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LLDumperSelectableTableView;

@protocol LLDumperSelectableTableViewDelegate <NSTableViewDelegate>

 @optional
/*!
	\brief
	Called whenever a key down is intercepted.
	Return nil if you decide to handle the event, return the original event otherwise.
 */
- (NSEvent *)selectableTableView:(LLDumperSelectableTableView *)table keyDown:(NSEvent *)event;

@end

@interface LLDumperSelectableTableView : NSTableView

- (void)setDelegate:(id <LLDumperSelectableTableViewDelegate>)delegate;
- (id <LLDumperSelectableTableViewDelegate>)delegate;

@end
