//
//  LLDumperPromiseOperation.h
//  Dumper Common
//
//  Created by Damien DeVille on 4/9/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLDumperPromiseOperation : NSOperation

+ (id)promiseOperationWithBlock:(id (^)(NSError **errorRef))block;

@property (readonly, copy, atomic) id (^completionProvider)(NSError **errorRef);

@end
