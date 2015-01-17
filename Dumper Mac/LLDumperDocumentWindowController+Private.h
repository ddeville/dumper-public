//
//  LLDumperDocumentWindowController+Private.h
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDocumentWindowController.h"

@interface LLDumperDocumentWindowController (Private)

- (void)_prepareInterfaceForExtractingHeadersInExecutableAtLocation:(NSURL *)executableLocation;

@end
