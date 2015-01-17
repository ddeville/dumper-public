//
//  LLDumperDocumentWindowController.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LLDumperDocument;
@class LLDumperExecutableLoadingViewController, LLDumperHeaderListViewController, LLDumperHeaderDetailsViewController;

@interface LLDumperDocumentWindowController : NSWindowController

@property (readonly, assign, nonatomic) IBOutlet LLDumperExecutableLoadingViewController *executableLoadingViewController;
@property (readonly, assign, nonatomic) IBOutlet NSView *executableLoadingContentView;

@property (readonly, assign, nonatomic) IBOutlet NSSplitView *headerSplitView;

@property (readonly, assign, nonatomic) IBOutlet LLDumperHeaderListViewController *headersListViewController;
@property (readonly, assign, nonatomic) IBOutlet NSView *headersListContentView;

@property (readonly, assign, nonatomic) IBOutlet LLDumperHeaderDetailsViewController *headerDetailsViewController;
@property (readonly, assign, nonatomic) IBOutlet NSView *headerDetailsContentView;

- (LLDumperDocument *)document;

- (IBAction)exportHeaders:(id)sender;

@end
