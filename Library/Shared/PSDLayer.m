//
//  PSDLayer.m
//  PSDWriterLibrary
//
//  Created by Ben Gotow on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PSDLayer.h"

@implementation PSDLayer

@synthesize imageData, name, opacity, rect, blendMode;

- (void)dealloc
{
    [imageData release];
    [name release];
    [super dealloc];
}

@end
