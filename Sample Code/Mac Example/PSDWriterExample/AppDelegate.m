//
//  AppDelegate.m
//  PSDWriterExample
//
//  Created by Ben Gotow on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "PSDWriter.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // grab the two images that we'll use
    NSImage * layer1 = [[[NSImage alloc] initWithContentsOfFile: @"./../../../Images/layer1.png"] autorelease];
    NSImage * layer2 = [[[NSImage alloc] initWithContentsOfFile: @"./../../../Images/layer2.png"] autorelease];
    if (!layer1 || !layer2) {
        NSLog(@"Example will fail - images missing!");
    }
    
    // Initialize a new PSD writer with the desired canvas size
    PSDWriter * w = [[PSDWriter alloc] initWithDocumentSize: CGSizeMake(900, 900)];
    
    // Add our first layer
    CGImageRef layer1CG = [self newCGImageForNSImage: layer1];
    [w addLayerWithCGImage:layer1CG andName:@"Island Layer" andOpacity:1 andOffset:CGPointZero];
    CGImageRelease(layer1CG);
    
    // Add our second layer
    CGImageRef layer2CG = [self newCGImageForNSImage: layer2];
    [w addLayerWithCGImage:layer2CG andName:@"Apple Layer" andOpacity:0.5 andOffset:CGPointMake(100, 100)];
    CGImageRelease(layer2CG);
    
    // Create the PSD data
    NSData * psd = [w createPSDData];
    
    // write the PSD data to disk and then open the image in Photoshop
    [psd writeToFile:@"./output.psd" atomically:NO];
    [[NSWorkspace sharedWorkspace] openFile: @"./output.psd"];
    
    // clean up!
    [w release];
}

- (CGImageRef)newCGImageForNSImage:(NSImage*)i
{
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[i TIFFRepresentation], NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    return imageRef;
}

@end
