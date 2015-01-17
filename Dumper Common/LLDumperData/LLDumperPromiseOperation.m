//
//  LLDumperPromiseOperation.m
//  Dumper Common
//
//  Created by Damien DeVille on 4/9/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import "LLDumperPromiseOperation.h"

@interface LLDumperPromiseOperation ()

@property (readwrite, copy, atomic) id (^completionProvider)(NSError **errorRef);
@property (copy, nonatomic) id (^block)(NSError **);

@end

@implementation LLDumperPromiseOperation

+ (id)promiseOperationWithBlock:(id (^)(NSError **errorRef))block
{
	NSParameterAssert(block != nil);
	
	LLDumperPromiseOperation *promise = [[LLDumperPromiseOperation alloc] init];
	[promise setBlock:block];
	return promise;
}

- (void)main
{
	if ([self isCancelled]) {
		return;
	}
	
	NSError *resultError = nil;
	id result = [self block](&resultError);
	
	if (result == nil) {
		NSParameterAssert(resultError != nil);
		
		[self setCompletionProvider:^ id (NSError **errorRef) {
			if (errorRef != NULL) {
				*errorRef = resultError;
			}
			return nil;
		}];
		return;
	}
	
	[self setCompletionProvider:^ id (NSError **errorRef) {
		return result;
	}];
}

@end
