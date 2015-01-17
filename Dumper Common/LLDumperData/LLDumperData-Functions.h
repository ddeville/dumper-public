//
//  LLDumperData-Functions.h
//  Dumper Common
//
//  Created by Damien DeVille on 1/4/14.
//  Copyright (c) 2014 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSArray *LLDumperDocumentLocationsInDirectory(NSURL *location, BOOL skipsSubdirectoryDescendants);

extern BOOL LLDumperCoordinateMoveItemAvoidingNameConflicts(NSURL *originLocation, NSURL *destinationLocation, NSError **errorRef);
