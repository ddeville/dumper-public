//
//  LLDumperTableView.h
//  Dumper
//
//  Created by Damien DeVille on 8/2/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LLDumperTableViewDelegate <NSTableViewDelegate>

 @optional
- (NSMenu *)tableView:(NSTableView *)tableView contextMenuForRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView contextMenuDidCloseForRow:(NSInteger)row;

@end

@interface LLDumperTableView : NSTableView <NSMenuDelegate>

- (NSMenu *)contextMenuForRow:(NSInteger)row;

@property (assign, nonatomic) id <LLDumperTableViewDelegate> delegate;

@end
