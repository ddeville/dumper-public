//
//  LLDumperDocumentHeadersExportOperation.h
//  Dumper Common
//
//  Created by Damien DeVille on 12/17/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLDumperDocumentHeadersExportOperation : NSOperation

- (id)initWithHeaders:(NSDictionary *)headers exportLocation:(NSURL *)exportLocation;

@property (readonly, copy, atomic) NSURL * (^completionProvider)(NSError **errorRef);

@end
