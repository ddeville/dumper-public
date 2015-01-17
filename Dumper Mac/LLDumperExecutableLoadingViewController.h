//
//  LLDumperExecutableLoadingViewController.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LLDumperExecutableLoadingViewControllerDelegate;

@interface LLDumperExecutableLoadingViewController : NSViewController

@property (readonly, assign, nonatomic) IBOutlet NSButton *dropzoneButton;

- (IBAction)chooseExecutable:(id)sender;

@property (weak, nonatomic) IBOutlet id <LLDumperExecutableLoadingViewControllerDelegate> delegate;

@property (assign, getter = isLoading, nonatomic) BOOL loading;

@end

@protocol LLDumperExecutableLoadingViewControllerDelegate <NSObject>

 @required
- (void)executableLoadingViewController:(LLDumperExecutableLoadingViewController *)executableLoadingViewController didChooseExecutableAtLocation:(NSURL *)executableLocation;

@end
