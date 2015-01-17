//
//  LLDumperTheme.h
//  Dumper Common
//
//  Created by Damien DeVille on 12/20/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLDumperTheme : NSObject

@property (readonly, copy, nonatomic) NSString *identifier;
extern NSString * const LLDumperThemeIdentifierKey;

@property (readonly, assign, getter = isEditable, nonatomic) BOOL editable;
extern NSString * const LLDumperThemeEditableKey;

@property (copy, nonatomic) NSString *name;
extern NSString * const LLDumperThemeNameKey;

@property (strong, nonatomic) id backgroundColor;
extern NSString * const LLDumperThemeBackgroundColorKey;

@property (strong, nonatomic) id selectionColor;
extern NSString * const LLDumperThemeSelectionColorKey;

@property (strong, nonatomic) id plainColor;
extern NSString * const LLDumperThemePlainColorKey;

@property (strong, nonatomic) id attributeColor;
extern NSString * const LLDumperThemeAttributeColorKey;

@property (strong, nonatomic) id keywordColor;
extern NSString * const LLDumperThemeKeywordColorKey;

@property (strong, nonatomic) id classColor;
extern NSString * const LLDumperThemeClassColorKey;

@property (strong, nonatomic) id commentColor;
extern NSString * const LLDumperThemeCommentColorKey;

@property (strong, nonatomic) id preprocessorColor;
extern NSString * const LLDumperThemePreprocessorColorKey;

@property (strong, nonatomic) id stringColor;
extern NSString * const LLDumperThemeStringColorKey;

- (void)updateColorsFromTheme:(LLDumperTheme *)theme;

@end

@interface LLDumperTheme (PropertyList)

- (id)initWithPropertyListRepresentation:(id)propertyListRepresentation;
- (id)propertyListRepresentation;

@end
