//
//  LLDumperClassListViewController.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LLDumperDocument;

@interface LLDumperHeaderListViewController : NSViewController

@property (readonly, assign, nonatomic) IBOutlet NSTableView *headersTableView;
@property (readonly, assign, nonatomic) IBOutlet NSArrayController *headersArrayController;

@property (readonly, assign, nonatomic) IBOutlet NSSearchField *searchField;
@property (readonly, assign, nonatomic) IBOutlet NSMenu *contextualMenu;

- (IBAction)openHeaderInExternalEditor:(id)sender;

extern NSString * const LLDumperHeaderListViewControllerSelectedHeaderFilename;
@property (copy, nonatomic) NSString *selectedHeaderFilename;

@property (weak, nonatomic) LLDumperDocument *document;

@end
