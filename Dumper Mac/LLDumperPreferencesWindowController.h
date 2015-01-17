//
//  LLDumperPreferencesWindowController.h
//  Dumper
//
//  Created by Damien DeVille on 8/3/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LLDumperThemeController;

@interface LLDumperPreferencesWindowController : NSWindowController

@property (strong, nonatomic) LLDumperThemeController *themeController;

- (IBAction)showGeneral:(id)sender;
- (IBAction)showThemes:(id)sender;

@end
