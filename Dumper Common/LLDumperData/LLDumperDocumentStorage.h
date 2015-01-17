//
//  LLDumperDocumentStorage.h
//  Dumper Common
//
//  Created by Damien DeVille on 12/17/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLDumperDocumentStorage : NSObject

- (id)initWithFileType:(NSString *)fileType;

@property (strong, nonatomic) NSDictionary *info;
@property (strong, nonatomic) NSDictionary *headers;

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)errorRef;
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)errorRef;

@end

extern NSString * const LLDumperDocumentStorageInfoVersionKey;
extern NSString * const LLDumperDocumentStorageInfoCreationDateKey;

@interface LLDumperDocumentStorage (Conveniences)

@property (readonly, strong, nonatomic) NSArray *sortedHeaderFilenames;

@end