PSDWriter
======

A few years ago, I wrote an app called [Layers](http://layersforiphone.com/) for iPhone and iPad. It was the first painting app for iPhone to support multiple layers, and one of it's killer features was the ability to email drawings as layered PSDs. Many people have asked me about PSD functionality over the years and I'm excited to release this code to the community. If you find it useful, please let me know and consider mentioning PSDWriter on your app's about screen. Though this code probably looks straightforward, it took forever to get working. To this day, I can still read PSD files by hand as hex. 

*Note: This library only writes PSDs, it does not read them. Because there are many versions of the PSD spec, and newer versions have a gazillion features, it's much easier to write a simple, layered PSD file than it is to read PSD. I have no plans to read PSD files anytime soon.*

###Write a PSD file (iOS):


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


###Write a PSD file (Mac OS X):

	// grab the two images that we'll use
    NSImage * layer1 = [[[NSImage alloc] initWithContentsOfFile: @"layer1.png"] autorelease];
    NSImage * layer2 = [[[NSImage alloc] initWithContentsOfFile: @"layer2.png"] autorelease];
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
    
    
## Going Further

This is a pretty basic implementation that I created for the [Layers](http://layersforiphone.com/) app. If you extend the library to do more, submit a pull request!

If you're interested in learning more about the PSD file format or need a copy of the PSD spec to extend PSDWriter, check out the [documentation on Adobe's website](http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/PhotoshopFileFormats.htm#50577409_72092). A word of wisdom: implement the oldest version of the PSD file format that supports what you need. Each successive version seems to be more complicated than the last. PSDWriter was written using the 2003 spec, which is much simpler than the current version.