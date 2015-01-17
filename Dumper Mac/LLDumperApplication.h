//
//  LLDumperApplication.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LLDumperWelcomeWindowController, LLDumperPreferencesWindowController, LLDumperThemeController;

@interface LLDumperApplication : NSApplication

+ (LLDumperApplication *)sharedApplication;

@property (readonly, strong, nonatomic) LLDumperThemeController *themeController;

@property (readonly, strong, nonatomic) LLDumperWelcomeWindowController *welcomeWindowController;
@property (readonly, strong, nonatomic) LLDumperPreferencesWindowController *preferencesWindowController;

- (IBAction)openPreferences:(id)sender;
- (IBAction)installCommandLineTools:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)viewLicense:(id)sender;

- (IBAction)openWelcomeWindow:(id)sender;
- (IBAction)openDumperSupport:(id)sender;
- (IBAction)openDumperProductPage:(id)sender;

- (IBAction)newDumperDocument:(id)sender;

@end
