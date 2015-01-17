//
//  LLDumperRecentDocument.h
//  Dumper
//
//  Created by Damien DeVille on 8/4/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLDumperRecentDocument : NSObject

@property (copy, nonatomic) NSString *filename;
@property (copy, nonatomic) NSURL *URL;

@end
