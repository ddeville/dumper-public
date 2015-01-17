//
//  NSURL+LLDumperExtensions.m
//  Dumper Mac
//
//  Created by Damien DeVille on 4/21/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import "NSURL+LLDumperExtensions.h"

@implementation NSURL (LLDumperExtensions)

- (NSDictionary *)ll_queryParameters
{
	NSMutableDictionary *queryComponents = [NSMutableDictionary dictionary];
	
	NSString * (^urlDecode) (NSString *) = ^ NSString * (NSString *urlEncodedValue) {
		NSString *decodedValue = [urlEncodedValue stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		decodedValue = [decodedValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		return decodedValue;
	};
	
	[[[self query] componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^ (NSString *parameterPair, NSUInteger idx, BOOL *stop) {
		NSArray *pairComponents = [parameterPair componentsSeparatedByString:@"="];
		if ([pairComponents count] == 0) {
			return;
		}
		
		NSString *key = urlDecode([pairComponents objectAtIndex:0]);
		NSString *value = ([pairComponents count] > 1 ? urlDecode([pairComponents objectAtIndex:1]) : @"");
		
		if (key == nil || value == nil) {
			return;
		}
		
		NSString *currentValues = [queryComponents objectForKey:key];
		if (currentValues == nil) {
			[queryComponents setObject:value forKey:key];
		}
		else {
			currentValues = [currentValues stringByAppendingFormat:@",%@", value];
			[queryComponents setObject:currentValues forKey:key];
		}
	}];
	
	return queryComponents;
}

@end
