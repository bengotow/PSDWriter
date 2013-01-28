//
//  ViewController.m
//  iOS Example
//
//  Created by Ben Gotow on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "PSDWriter.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // grab the two images that we'll use
    UIImage * image1 = [UIImage imageNamed:@"layer1.png"];
    UIImage * image2 = [UIImage imageNamed:@"layer2.png"];
    
    // Initialize a new PSD writer with the desired canvas size
    PSDWriter * w = [[PSDWriter alloc] initWithDocumentSize: CGSizeMake(900, 900)];
    
    // Add our first layer
    [w addLayerWithCGImage:[image1 CGImage] andName:@"Island Layer" andOpacity:1 andOffset:CGPointMake(500, 700)];
    
    // Add our second layer
    [w addLayerWithCGImage:[image2 CGImage] andName:@"Apple Layer" andOpacity:1 andOffset:CGPointMake(500, 700)];
    
    // Create the PSD data
    NSData * psd = [w createPSDData];
    
    
    // write the PSD data to disk (in the simulator, this will put it on the root level
    // of your boot volume). On the actual device, we'd have to email it or something
    [psd writeToFile:@"/output.psd" atomically:NO];
    
    // clean up!
    [w release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
