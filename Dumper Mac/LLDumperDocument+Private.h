//
//  LLDumperDocument+Private.h
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "LLDumperDocument.h"

@interface LLDumperDocument (Private)

- (void)_extractHeadersInExectuableAtLocation:(NSURL *)bundleOrExecutableLocation completion:(void (^)(BOOL success, NSError *error))completion;

@end
