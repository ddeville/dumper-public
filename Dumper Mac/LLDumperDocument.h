//
//  LLDumperDocument.h
//  Dumper
//
//  Created by Damien DeVille on 8/1/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LLDumperDocument : NSDocument

@property (readonly, strong, nonatomic) NSDictionary *headers;

@property (readonly, strong, nonatomic) NSArray *headerFilenames;
- (NSString *)headerContentWithFilename:(NSString *)filename;

/*!
	\brief
	Run class-dump on the given executable.
 */
- (void)extractHeadersInExectuableAtLocation:(NSURL *)bundleOrExecutableLocation;

+ (NSArray *)allowedImportFileTypes;
+ (NSOpenPanel *)importOpenPanel;

@end
