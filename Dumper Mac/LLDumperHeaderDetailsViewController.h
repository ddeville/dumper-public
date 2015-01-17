//
//  LLDumperClassDetailsViewController.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LLDumperHeaderDetailsViewController : NSViewController

@property (readonly, assign, nonatomic) IBOutlet NSTextView *textView;

- (void)updateText:(NSString *)text;

@end
