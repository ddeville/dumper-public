//
//  LLDumperWelcomeWindowController.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LLDumperWelcomeWindowController : NSWindowController

@property (readonly, assign, nonatomic) IBOutlet NSTableView *recentDocumentsTableView;
@property (readonly, assign, nonatomic) IBOutlet NSArrayController *recentDocumentsArrayController;

- (IBAction)viewFrameworks:(id)sender;
- (IBAction)viewApplications:(id)sender;

@end
