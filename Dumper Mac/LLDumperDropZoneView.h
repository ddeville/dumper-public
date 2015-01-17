//
//  LLDumperDropZoneView.h
//  Dumper
//
//  Created by Damien DeVille on 8/2/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LLDumperDropZoneViewDelegate;

@interface LLDumperDropZoneView : NSView <NSDraggingDestination>

@property (weak, nonatomic) IBOutlet id <LLDumperDropZoneViewDelegate> delegate;

@end

@protocol LLDumperDropZoneViewDelegate <NSObject>

 @optional
- (NSDragOperation)dropZoneView:(LLDumperDropZoneView *)dropZoneView draggingEntered:(id <NSDraggingInfo>)dropInfo;
- (void)dropZoneView:(LLDumperDropZoneView *)dropZoneView draggingExited:(id <NSDraggingInfo>)dropInfo;

- (BOOL)dropZoneView:(LLDumperDropZoneView *)dropZoneView acceptDrop:(id <NSDraggingInfo>)dropInfo;

@end
