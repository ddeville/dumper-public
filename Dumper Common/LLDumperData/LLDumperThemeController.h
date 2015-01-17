//
//  LLDumperThemeController.h
//  Dumper Common
//
//  Created by Damien DeVille on 1/8/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LLDumperTheme;

@interface LLDumperThemeController : NSObject

@property (readonly, strong, nonatomic) NSArray *themes;
extern NSString * const LLDumperThemeControllerThemesKey;

@property (strong, nonatomic) LLDumperTheme *currentTheme;
extern NSString * const LLDumperThemeControllerCurrentThemeKey;

- (void)addTheme:(LLDumperTheme *)theme;
- (void)duplicateTheme:(LLDumperTheme *)theme;
- (void)updateTheme:(LLDumperTheme *)theme;
- (void)removeTheme:(LLDumperTheme *)theme;

+ (NSArray *)defaultThemes;

@end
