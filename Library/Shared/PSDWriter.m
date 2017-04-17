//
//  PSDWriter.m
//  PSDWriter
//
//  Created by Ben Gotow on 5/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PSDWriter.h"
#import "NSDataPSDAdditions.h"
#import "PSDLayer.h"

 char signature8BIM[4] = {'8','B','I','M'};

// Blend mode key: 'pass' = pass through,
// 'norm' = normal, 'diss' = dissolve, 'dark' = darken, 'mul ' = multiply,
char blendModeNormKey[4] = {'n','o','r','m'};
char blendModeDissKey[4] = {'d','i','s','s'};
char blendModeDarkKey[4] = {'d','a','r','k'};
char blendModeMulKey[4] = {'m','u','l',' '};
// 'idiv' = color burn, 'lbrn' = linear burn, 'dkCl' = darker color, 'lite' = lighten,
char blendModeIdivKey[4] = {'i','d','i','v'};
char blendModeLbrnKey[4] = {'l','b','r','n'};
char blendModeDkclKey[4] = {'d','k','C','l'};
char blendModeLiteKey[4] = {'l','i','t','e'};

// 'scrn' = screen, 'div ' = color dodge, 'lddg' = linear dodge, 'lgCl' = lighter
char blendModeScrnKey[4] = {'s','c','r','n'};
char blendModeDivKey[4] = {'d','i','v',' '};
char blendModeLddgKey[4] = {'l','d','d','g'};
char blendModeLgClKey[4] = {'l','g','C','l'};
// color, 'over' = overlay, 'sLit' = soft light, 'hLit' = hard light, 'vLit' = vivid light,
// 'lLit' = linear light, 'pLit' = pin light, 'hMix' = hard mix, 'diff' = difference,
// 'smud' = exclusion, 'fsub' = subtract, 'fdiv' = divide,
// 'hue ' = hue, 'sat ' = saturation, 'colr' = color, 'lum ' = luminosity,
char blendModeHueKey[4] = {'h','u','e',' '};
char blendModeSatKey[4] = {'s','a','t',' '};
char blendModeColKey[4] = {'c','o','l','r'};
char blendModeLumKey[4] = {'l','u','m',' '};
char *blendModes[36] =
{ &blendModeNormKey, &blendModeDissKey, &blendModeDarkKey, &blendModeMulKey,
    0 };


@implementation PSDWriter

@synthesize documentSize;
@synthesize layers;
@synthesize layerChannelCount;
@synthesize flattenedData;

@synthesize shouldFlipLayerData;
@synthesize shouldUnpremultiplyLayerData;

- (id)init
{
    self = [super init];
    if (self){
        layerChannelCount = 4;
        shouldFlipLayerData = NO;
        shouldUnpremultiplyLayerData = NO;
        flattenedContext = NULL;
        flattenedData = nil;
        layers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithDocumentSize:(CGSize)s
{
    self = [self init];
    if (self){
        documentSize = s;
    }
    return self;
}
- (void)addLayerWithCGImage:(CGImageRef)image
                    andName:(NSString*)name
                 andOpacity:(float)opacity
                  andOffset:(CGPoint)offset
{
    [self addLayerWithCGImage:(CGImageRef)image
                      andName:(NSString*)name
                   andOpacity:(float)opacity
                    andOffset:(CGPoint)offset
                 andBlendMode: kPSDBlendModeNormal];
    
}
- (void)addLayerWithCGImage:(CGImageRef)image
                    andName:(NSString*)name
                 andOpacity:(float)opacity
                  andOffset:(CGPoint)offset
               andBlendMode: (NSInteger) blendMode
{
    PSDLayer * l = [[[PSDLayer alloc] init] autorelease];
    
    CGRect imageRegion = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
    CGRect screenRegion = CGRectMake(offset.x, offset.y, imageRegion.size.width, imageRegion.size.height);
    CGRect drawRegion = CGRectMake(offset.x, offset.y, imageRegion.size.width, imageRegion.size.height);

    if (screenRegion.origin.x + screenRegion.size.width > documentSize.width)
        imageRegion.size.width = screenRegion.size.width = documentSize.width - screenRegion.origin.x;
    if (screenRegion.origin.y + screenRegion.size.height > documentSize.height)
        imageRegion.size.height = screenRegion.size.height = documentSize.height - screenRegion.origin.y;
    if (screenRegion.origin.x < 0) {
        imageRegion.origin.x = abs(screenRegion.origin.x);
        screenRegion.origin.x = 0;
        screenRegion.size.width = imageRegion.size.width = imageRegion.size.width - imageRegion.origin.x;
    }
    if (screenRegion.origin.y < 0) {
        imageRegion.origin.y = abs(screenRegion.origin.y);
        screenRegion.origin.y = 0;
        screenRegion.size.height = imageRegion.size.height = imageRegion.size.height - imageRegion.origin.y;
    }
    // get part of the image that fix on the screen.
    [l setImageData: CGImageGetData(image, imageRegion)];
    [l setOpacity: opacity];
    [l setRect: screenRegion];
    [l setName: name];  // 0 - 15 char kept currently (padded with spaces)
    [l setBlendMode:blendMode]; // Normal = 0.
    
    [layers addObject: l];

    if (flattenedData == nil) {
        if ((documentSize.width == 0) || (documentSize.height == 0))
            @throw [NSException exceptionWithName:NSGenericException reason:@"You must specify a non-zero documentSize before calling addLayer:" userInfo:nil];

        if (flattenedContext == NULL) {
            flattenedContext = CGBitmapContextCreate(NULL, documentSize.width, documentSize.height, 8, 0, CGImageGetColorSpace(image), kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
            CGContextSetRGBFillColor(flattenedContext, 1, 1, 1, 1);
            CGContextFillRect(flattenedContext, CGRectMake(0, 0, documentSize.width, documentSize.height));
        }
        drawRegion.origin.y = documentSize.height - (drawRegion.origin.y + drawRegion.size.height);
        CGContextSetAlpha(flattenedContext, opacity);
        CGContextDrawImage(flattenedContext, drawRegion, image);
        CGContextSetAlpha(flattenedContext, opacity);
    }
}

/* Generates an NSData object representing a PSD image. 
   LayerData should contain an array of NSData
 objects representing the RGBA layer data (8 bits per component) and a width and height of size.
 flatData should contain the RGBA data of a single image made by flattening all of the layers. */

- (void)dealloc
{
    if (flattenedContext != NULL) {
        CGContextRelease(flattenedContext);
        flattenedContext = nil;
    }

	[layers release];
	layers = nil;
	[flattenedData release];
	flattenedData = nil;

	[super dealloc];
}

- (void)preprocess
{
    // do we have a flattenedContext that needs to become flattenedData?
    if (flattenedData == nil) {
        if (flattenedContext) {
            CGImageRef i = CGBitmapContextCreateImage(flattenedContext);
            flattenedData = [CGImageGetData(i, CGRectMake(0, 0, documentSize.width, documentSize.height)) retain];
            CGImageRelease(i);
        }
    }
    if (flattenedContext) {
        CGContextRelease(flattenedContext);
        flattenedContext = nil;

    }

	if ((self.shouldFlipLayerData == NO) && (self.shouldUnpremultiplyLayerData == NO))
		return;

    for (PSDLayer * layer in layers)
	{
        NSData *d = [layer imageData];

		// sketchy? yes. fast? oh yes.
		UInt8 *data = (UInt8 *)[d bytes];
		unsigned long length = [d length];

		if (self.shouldUnpremultiplyLayerData) {
			// perform unpremultiplication
			for(long i = 0; i < length; i+=4) {
				float a = ((float)data[(i + 3)]) / 255.0;
				data[(i+0)] = (int) fmax(0, fmin((float)data[(i+0)] / a, 255));
				data[(i+1)] = (int) fmax(0, fmin((float)data[(i+1)] / a, 255));
				data[(i+2)] = (int) fmax(0, fmin((float)data[(i+2)] / a, 255));
			}
		}

		if (self.shouldFlipLayerData) {
			// perform flip over vertical axis
			for (int x = 0; x < documentSize.width; x++) {
				for (int y = 0; y < documentSize.height/2; y++) {
					int top_index = (x+y*documentSize.width) * 4;
					int bottom_index = (x+(documentSize.height-y-1)*documentSize.width) * 4;
					char saved;

					for (int a = 0; a < 4; a++) {
						saved = data[top_index+a];
						data[top_index+a] = data[bottom_index+a];
						data[bottom_index+a] = saved;
					}
				}
			}
		}
	}
}

// RMF Adding effects - work in progress not tested or debugged.
- (NSMutableData *) makeEffectLayer
{    // The key for the effects layer is 'lrFX' .
    char effectKey[4] = {'l','r','F','X'};

    NSMutableData *effectInfo = [[NSMutableData alloc] init];

    NSInteger effectCnt = 1;  // Effects count: may be 6 (for the 6 effects in Photoshop 5 and 6) or 7 (for Photoshop 7.0)
    if (effectCnt> 7) NSLog(@"Effect Count Error");
    
     /*   Additional layer information - to hold effect layers
      4 Signature: '8BIM' 
      4 Key: a 4-character code - The key for the effects layer is 'lrFX'
      4 Length data below, rounded up to an even byte count.  */
    
    NSUInteger effectLenght = 4 + 19 + 41 ;
    
    [effectInfo appendBytes:&signature8BIM length:4];
    [effectInfo appendBytes:&effectKey length:4];
    effectLenght = effectLenght + (effectLenght % 2);   // round up to even
    [effectInfo appendBytes:effectLenght length:4];

    // add Effect header
    [effectInfo appendValue:0 withLength:2];    // verison 0
    [effectInfo appendValue:effectCnt withLength:2];    // Effects count: may be 6 (for the 6 effects in Photoshop 5 and 6) or 7 (for Photoshop 7.0)
   
    /*
     for each effect active.. 
        ouput: sign, Effects keys and effect data strucutre.
    
      Effects keys: OSType key for which effects type to use:
        'cmnS' = common state (see See Effects layer, common state info)
        'dsdw' = drop shadow (see See Effects layer, drop shadow and inner shadow info)
        'isdw' = inner shadow (see See Effects layer, drop shadow and inner shadow info)
        'oglw' = outer glow (see See Effects layer, outer glow info)
        'iglw' = inner glow (see See Effects layer, inner glow info)
        'bevl' = bevel (see See Effects layer, bevel info)
        'sofi' = solid fill ( Photoshop 7.0) (see See Effects layer, solid fill (added in Photoshop 7.0)) */
    char effectCommonState[4] = {'c','m','n','S'};
    char effectDropShadow[4] = {'d','s','d','w'};
 /*   char effectInnerShadow[4] = {'i','s','d','w'};
    char effectOuterGlow[4] = {'o','g','l','w'};
    char effectInnerGlow[4] = {'i','g','l','w'};
    char effectBevel[4] = {'b','e','v','l'};  */

    // commmon State (size = 19 bytes)
    [effectInfo appendBytes:&signature8BIM length:4];
    [effectInfo appendBytes:&effectCommonState length:4];
    [effectInfo appendValue:7 withLength:4];
    [effectInfo appendValue:0 withLength:4];
    [effectInfo appendValue:1 withLength:1];
    [effectInfo appendValue:0 withLength:2];
    
    // cDropShadow (size = ? bytes)
/*  Length Description
     4  Size of the remaining items: 41 or 51 (depending on version)
     4  Version: 0 ( Photoshop 5.0) or 2 ( Photoshop 5.5)
     4  Blur value in pixels
     4  Intensity as a percent
     4  Angle in degrees
     4  Distance in pixels
     10 Color: 2 bytes for space followed by 4 * 2 byte color component
     8  Blend mode: 4 bytes for signature and 4 bytes for key
     1  Effect enabled
     1  Use this angle in all of the layer effects
     1  Opacity as a percent
     10 Native color: 2 bytes for space followed by 4 * 2 byte color component
     */
    if (1) {    // dropshadow effect
    int dsBlurInPixels = 3;
    int dsIntensity = 90;   // 0-100%
    int dsDistanceInPixels = 5;
    int dsAngle = 60;   // in Degrees

    [effectInfo appendBytes:&signature8BIM length:4];
    [effectInfo appendBytes:&effectDropShadow length:4];
    [effectInfo appendValue:41 withLength:4];
    [effectInfo appendValue:0 withLength:4];    // photoshop 5.0
    [effectInfo appendValue:dsBlurInPixels withLength:4];
    [effectInfo appendValue:dsIntensity withLength:4];
    [effectInfo appendValue:dsAngle withLength:4];
    [effectInfo appendValue:dsDistanceInPixels withLength:4];
    // FIXME -- color output
    [effectInfo appendValue:255 + 255*256+255*256*256 withLength:10];   // color
            // Blend Mode
    [effectInfo appendBytes:&signature8BIM length:4];
    [effectInfo appendBytes:blendModes[kPSDBlendModeNormal] length:4];
    [effectInfo appendValue:1 withLength:1];    // Effect enabled
    [effectInfo appendValue:0 withLength:1];    // Use this angle in all of the layer effects
    [effectInfo appendValue:75 withLength:1];    // Opacity as a percent
    }

}

- (NSData *)createPSDData
{
	char signature8BPS[4] = {'8','B','P','S'};
//	char signature8BIM[4] = {'8','B','I','M'};
       

	NSMutableData *result = [NSMutableData data];

	// make sure the user has provided everything we need
	if ((layerChannelCount < 3) || ([layers count] == 0))
        @throw [NSException exceptionWithName:NSGenericException reason:@"Please provide layer data, flattened data and set layer channel count to at least 3." userInfo:nil];


	// modify the input data if necessary
	[self preprocess];

#pragma mark    FILE HEADER SECTION
	// -------------------------------------------------------------------------------
  	// write the signature
	[result appendBytes:&signature8BPS length:4];

	// write the version number
	[result appendValue:1 withLength:2];

	// write reserved blank space
	[result appendValue:0 withLength:6];

	// write number of channels (Supported range is 1 to 56)
	[result appendValue:layerChannelCount withLength:2];

	// write height then width of the image in pixels. Supported range is 1 to 30,000.
	[result appendValue:documentSize.height withLength:4];
	[result appendValue:documentSize.width withLength:4];

	// write number of bits per channel (we only suppot 8,
    // Valid values are 1, 8, 16 and 32.)
	[result appendValue:8 withLength:2];

	// write color mode (3 = RGB)
    // Valid values are:  Bitmap = 0; Grayscale = 1; Indexed = 2; RGB = 3;
    //                        CMYK = 4; Multichannel = 7; Duotone = 8; Lab = 9.
	[result appendValue:3 withLength:2];

#pragma mark  COLOR MODE DATA SECTION - Only indexed color and duotone
	// ---------------------------------------------------------------------------------------
	// write color mode data section
    // Only indexed color and duotone
    // (see the mode field in the File header section) have color mode data.
    // For all other modes, this section is just the 4-byte length field, which is set to zero.
    // Indexed color images: length is 768; color data contains the color table for the image, in non-interleaved order.
	[result appendValue:0 withLength:4];

#pragma mark    IMAGE RESOURCES SECTION
	// -------------------------------------------------------------------------------------
	// write images resources section. This is used to store things like current layer.
	NSMutableData *imageResources = [[NSMutableData alloc] init];
	/*
     1005   ResolutionInfo structure
            See Appendix A in Photoshop API Guide.pdf .

     1008   The caption as a Pascal string.

     •1028  IPTC-NAA record
            Contains the File Info... information.
            See the documentation in the IPTC folder of the Documentation folder.

     •1039  (Photoshop 5.0) ICC Profile
            The raw bytes of an ICC (International Color Consortium) format profile.
            See ICC1v42_2006-05.pdf in the Documentation folder and icProfileHeader.h in Sample Code\Common\Includes .
     ••••••••

     1054   (Photoshop 6.0) URL List
            4 byte count of URLs, followed by 4 byte long, 4 byte ID, and Unicode string for each count.

     1058   (Photoshop 7.0) EXIF data 1
            See http://www.kodak.com/global/plugins/acrobat/en/service/digCam/exifStandard2.pdf
     •••••••••••••1059  (Photoshop 7.0) EXIF data 3
            See http://www.kodak.com/global/plugins/acrobat/en/service/digCam/exifStandard2.pdf
     •••••••••••••1060  (Photoshop 7.0) XMP metadata
            File info as XML description. See http://www.adobe.com/devnet/xmp/

     1065   (Photoshop CS) Layer Comps
            4 bytes (descriptor version = 16), Descriptor (see See Descriptor structure)

     1069   (Photoshop CS2) Layer Selection ID(s)
            2 bytes count, following is repeated for each count: 4 bytes layer ID

     1072   (Photoshop CS2) Layer Group(s) Enabled ID
            1 byte for each layer in the document, repeated by length of the resource.
            NOTE: Layer groups have start and end markers
     */

	/*
	 // Naming the alpha channels isn't necessary, but here's how:
	 // Apparently those bytes contain 2 pascal strings? I think the last one is zero chars.
	 [imageResources appendBytes:&signature8BIM length:4];
	 [imageResources appendValue:1006 withLength:2];
	 [imageResources appendValue:0 withLength:2];
	 [imageResources appendValue:19 withLength:4];
	 Byte nameBytes[20] = {0x0C,0x54,0x72,0x61,0x6E,0x73,0x70,0x61,0x72,0x65,0x6E,0x63,0x79,0x05,0x45,0x78,0x74,0x72,0x61,0x00};
	 [imageResources appendBytes:&nameBytes length:20];
	 */

	// RES: write the resolutionInfo structure. Don't have the definition for this, so we
	// have to just paste in the right bytes.
	[imageResources appendBytes:&signature8BIM length:4];
	[imageResources appendValue:1005 withLength:2];
	[imageResources appendValue:0 withLength:2];
	[imageResources appendValue:16 withLength:4];

	Byte resBytes[16] = {0x00, 0x48, 0x00, 0x00,0x00,0x01,0x00,0x01,0x00,0x48,0x00,0x00,0x00,0x01,0x00,0x01};
	[imageResources appendBytes:&resBytes length:16];

	// write the current layer structure
    // RES: Layer state information
    //  2 bytes containing the index of target layer (0 = bottom layer).

	[imageResources appendBytes:&signature8BIM length:4];
	[imageResources appendValue:1024 withLength:2];
	[imageResources appendValue:0 withLength:2];
	[imageResources appendValue:2 withLength:4];
	[imageResources appendValue:0 withLength:2]; // current layer = 0

	[result appendValue:[imageResources length] withLength:4];
	[result appendData:imageResources];
	[imageResources release];


	// This is for later when we write the transparent top and bottom of the shape
	int transparentRowSize = sizeof(Byte) * (int)ceilf(documentSize.width * 4);
	Byte *transparentRow = malloc(transparentRowSize);
	memset(transparentRow, 0, transparentRowSize);

	NSData *transparentRowData = [NSData dataWithBytesNoCopy:transparentRow length:transparentRowSize freeWhenDone:NO];
	NSData *packedTransparentRowData = [transparentRowData packedBitsForRange:NSMakeRange(0, transparentRowSize) skip:4];

#pragma mark  LAYER + MASK INFORMATION SECTION
	// -----------------------------------------------------------------------------------------
	// layer and mask information section.
    // contains basic data about each layer (its mask, its channels,
	// its layer effects, its annotations, transparency layers, wtf tons of shit.)
    // We need to actually create this.
	/*
     The fourth section of a Photoshop file contains information about layers and masks.
     This section of the document describes the formats of layer and mask records.
     The complete merged image data is not stored here.
     The complete merged/composite image resides in the last section of the file.

     If there are no layers or masks, this section is just 4 bytes: the length field,
     which is set to zero. 
     NOTE: The length of the section may already be known.)
     */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	// build layer structure then add them to result
	NSMutableData *layerInfo = [[NSMutableData alloc] init];
    NSMutableArray *layerChannels = [NSMutableArray array];
	NSUInteger layerCount = [layers count];

    // Lenght value will be add at end.
	// write the layer count
	[layerInfo appendValue:layerCount withLength:2];
    
	for (int layer = 0; layer < layerCount; layer++)
	{   
		NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
        PSDLayer *aLayer = (PSDLayer*) [layers objectAtIndex:0];
        
		NSData *imageData = [aLayer imageData];
		CGRect bounds = [aLayer rect];
		bounds.origin.x = floorf(bounds.origin.x);
		bounds.origin.y = floorf(bounds.origin.y);
		bounds.size.width = floorf(bounds.size.width);
		bounds.size.height = floorf(bounds.size.height);

		// Check the bounds
		if (bounds.origin.x < 0 || bounds.origin.y < 0) {
			@throw [NSException exceptionWithName:@"LayerOutOfBounds"
										   reason:[NSString stringWithFormat:@"Layer %i's x or y origin is negative, which is unsupported", layer]
										 userInfo:nil];
		}
		if (bounds.origin.x + bounds.size.width > documentSize.width ||
			bounds.origin.y + bounds.size.height > documentSize.height) {
			@throw [NSException exceptionWithName:@"LayerOutOfBounds"
										   reason:[NSString stringWithFormat:@"Layer %i's bottom-right corner is beyond the edge of the canvas, which is unsupported", layer]
										 userInfo:nil];
		}

		int imageRowBytes = bounds.size.width * 4;  // 8bit RGBA = 4 bytes

        // process Channel image data for each layer.
        //
        // too much padding is going on here
        // FIX ME?  -- only need image data area.
		NSRange leftPackRange = NSMakeRange(0, (int)bounds.origin.x * 4);
		NSData *packedLeftOfShape = [transparentRowData packedBitsForRange:leftPackRange skip:4];
		NSRange rightPackRange = NSMakeRange(0, (int)(documentSize.width - bounds.origin.x - bounds.size.width) * 4);
		NSData *packedRightOfShape = [transparentRowData packedBitsForRange:rightPackRange skip:4];

		for (int channel = 0; channel < layerChannelCount; channel++)
		{
			NSMutableData *byteCounts = [[NSMutableData alloc] initWithCapacity:documentSize.height * layerChannelCount * 2];
			NSMutableData *scanlines = [[NSMutableData alloc] init];

			for (int row = 0; row < documentSize.height; row++)
			{
				// If it's above or below the shape's bounds, just write black with 0-alpha
				if (row < (int)bounds.origin.y ||
                    row >= (int)(bounds.origin.y + bounds.size.height)) {
					[byteCounts appendValue:[packedTransparentRowData length] withLength:2];
					[scanlines appendData:packedTransparentRowData];
				} else {
					int byteCount = 0;

					if (bounds.origin.x > 0.01) {
						// Append the transparent portion to the left of the shape
						[scanlines appendData:packedLeftOfShape];
						byteCount += [packedLeftOfShape length];
					}

					NSRange packRange = NSMakeRange((row - (int)bounds.origin.y) * imageRowBytes + channel, imageRowBytes);
					NSData *packed = [imageData packedBitsForRange:packRange skip:4];
					[scanlines appendData:packed];
					byteCount += [packed length];

					if (bounds.origin.x + bounds.size.width < documentSize.width) {
						// Append the transparent portion to the right of the shape
						[scanlines appendData:packedRightOfShape];
						byteCount += [packedRightOfShape length];
					}

					[byteCounts appendValue:byteCount withLength:2];
				}
			}
            
            // write channel layer structure..
            //
            // Image data.
            // If the compression code is 0, the image data is just the raw image data,
            // whose size is calculated as (LayerBottom- LayerTop)* (LayerRight-LayerLeft)
            // If the compression code is 1, the image data starts with the byte counts for all the scan lines in the channel (LayerBottom- LayerTop), with each count stored as a two-byte value.
            // The RLE compressed data follows, with each scan line compressed separately.
            // If the layer's size, and therefore the data, is odd, a pad byte will be inserted at the end of the row.
            
			NSMutableData *channelData = [[NSMutableData alloc] init];
			// write channel compression format
			[channelData appendValue:1 withLength:2];   // RLE = 1
			// write channel byte counts
			[channelData appendData:byteCounts];
			// write channel scanlines
			[channelData appendData:scanlines];

			// add completed channel data to channels array
			[layerChannels addObject:channelData];

			[channelData release];
			[byteCounts release];
			[scanlines release];
		}   // end for channel

		// print out top left bottom right 4x4
		[layerInfo appendValue:0 withLength:4];
		[layerInfo appendValue:0 withLength:4];
		[layerInfo appendValue:documentSize.height withLength:4];
		[layerInfo appendValue:documentSize.width withLength:4];

		// print out number of channels in the layer
		[layerInfo appendValue:layerChannelCount withLength:2];

		// print out data about each channel
		for (int c = 0; c < 3; c++) {
			[layerInfo appendValue:c withLength:2];
			[layerInfo appendValue:[[layerChannels objectAtIndex:c + layer * 4] length] withLength:4];
		}

		// for some reason, the alpha channel is number -1, not 3...
		Byte b[2] = {0xFF, 0xFF};
		[layerInfo appendBytes:&b length:2];
		[layerInfo appendValue:[[layerChannels objectAtIndex:3 + layer * 4] length] withLength:4];

		// print out blend mode signature
		[layerInfo appendBytes:&signature8BIM length:4];

		// print out blend type
 
        //	was:	[layerInfo appendBytes:&blendModeNormKey length:4];
        [layerInfo appendBytes:blendModes[[aLayer blendMode]] length:4];

		// print out opacity (0 = transparent ... 255 = opaque)
		int opacity = ceilf([aLayer opacity] * 255.0f);
		[layerInfo appendValue:opacity withLength:1];

		// print out  Clipping: 0 = base, 1 = non-base
		[layerInfo appendValue:0 withLength:1];

		// print out flags. I think we're making the layer invisible
        // Flags:
        //  bit 0 = transparency protected;
        //  bit 1 = visible; bit 2 = obsolete;
        //  bit 3 = 1 for Photoshop 5.0 and later, tells if bit 4 has useful information;
        //  bit 4 = pixel data irrelevant to appearance of document

		[layerInfo appendValue:1 withLength:1]; // Flags
		[layerInfo appendValue:0 withLength:1]; // filler 0

		// print out extra data length ( = the total length of the next five fields).
		[layerInfo appendValue:4+4+16 withLength:4];

		// print out extra data (mask info, layer name)
		[layerInfo appendValue:0 withLength:4]; // Can be 40 bytes, 24 bytes, or 4 bytes if no layer mask.
		[layerInfo appendValue:0 withLength:4];	// Layer blending ranges:
		//		char layerName[15] = {'L','a','y','e','r','s',' ','P','S','D',' ','1','2','3','4'};
		//		[layerInfo appendValue:15 withLength:1];
		//		[layerInfo appendBytes:&layerName length:15];

		//		NSString *layerNameString = [[layerNames objectAtIndex:layer] stringByAppendingString:@" "];
		//		[layerNameString getCString:layerName maxLength:15 encoding:NSStringEncodingConversionAllowLossy];

		NSString *layerName = [[aLayer name] stringByAppendingString:@" "];
		layerName = [layerName stringByPaddingToLength:15 withString:@" " startingAtIndex:0];
		const char *layerNameCString = [layerName cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
		// Layer name: Pascal string 1 byte length + text, padded to a multiple of 4 bytes.
		NSInteger len =  [layerName length] ;
		[layerInfo appendValue:len withLength:1];
		[layerInfo appendBytes:layerNameCString length:len];

		[layers removeObjectAtIndex:0];
		[outerPool release];
	}   // end for Layer

	free(transparentRow);

	// write the channel image data for each layer
	while([layerChannels count] > 0) {
		[layerInfo appendData:[layerChannels objectAtIndex:0]];
		[layerChannels removeObjectAtIndex:0];
	}
	[pool release];

	// round to length divisible by 2.
	if ([layerInfo length] % 2 != 0)
		[layerInfo appendValue:0 withLength:1];

#pragma mark - Add effect layers here.

    // Write Layer size then add layerdata  (from layerInfo).
	// write length of layer and mask information section
	[result appendValue:[layerInfo length]+4 withLength:4];

	// write length of layer info
	[result appendValue:[layerInfo length] withLength:4];
    

	// write out actual layer info
	[result appendData:layerInfo];
	[layerInfo release];

	// This should be required. I'm not sure why it works without it.
	// write out empty global layer section (globalLayerMaskLength == 0)
	// [self writeValue:0 toData:result withLength:4];

#pragma mark IMAGE DATA SECTION
	// ---------------------------------------------------------------------------------------
    /*  Image Data Section
     
     ￼The last section of a Photoshop file contains the image pixel data. 
     Image data is stored in planar order: first all the red data, then all the green data, etc.
     Each plane is stored in scan-line order, with no pad bytes,
    

     ￼￼￼￼￼￼￼￼Length Description
     ￼￼￼￼￼￼￼￼2  Compression method: 0 = Raw image data
     ￼
         ￼￼￼￼￼￼1 = RLE compressed the image data starts with the byte counts for all the scan lines (rows * channels), with each count stored as a two-byte value. The RLE compressed data follows, with each scan line compressed separately. The RLE compression is the same compression algorithm used by the Macintosh ROM routine PackBits , and the TIFF standard.
         2 = ZIP without prediction
         3 = ZIP with prediction.
     ￼￼￼￼￼￼￼￼Variable   The image data. Planar order = RRR GGG BBB, etc.
     */
	// write compression format = 1 = RLE
	[result appendValue:1 withLength:2];    // Compression.

	// With RLE compression, the image data starts with the byte counts for all of the scan lines (rows * channels)
	// with each count stored as a 2-byte value. The RLE compressed data follows with each scan line compressed
	// separately. Same as the TIFF standard.

	// in 512x512 image w/ no alpha, there are 3072 scan line bytes.
    // At 2 bytes each, that means 1536 byte counts.
	// 1536 = 512 rows * three channels.

	NSMutableData *byteCounts = [NSMutableData dataWithCapacity:documentSize.height * layerChannelCount * 2];
	NSMutableData *scanlines = [NSMutableData data];

	int imageRowBytes = documentSize.width * 4; 

	for (int channel = 0; channel < layerChannelCount; channel++) {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		for (int row = 0; row < documentSize.height; row++) {
			NSRange packRange = NSMakeRange(row * imageRowBytes + channel, imageRowBytes);
			NSData * packed = [flattenedData packedBitsForRange:packRange skip:4];
			[byteCounts appendValue:[packed length] withLength:2];
			[scanlines appendData:packed];
		}   // for row
		[pool release];
	}   // for channel (RGB or RGBA)

	// chop off the image data from the original file
	[result appendData:byteCounts];
	[result appendData:scanlines];

	return result;
}

@end


NSData *CGImageGetData(CGImageRef image, CGRect region)
{
	// Create the bitmap context
	CGContextRef	context = NULL;
	void *			bitmapData;
	int				bitmapByteCount;
	int				bitmapBytesPerRow;

	// Get image width, height. We'll use the entire image.
	int width = region.size.width;
	int height = region.size.height;

	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow = (width * 4);
	bitmapByteCount	= (bitmapBytesPerRow * height);

	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	//	bitmapData = malloc(bitmapByteCount);
	bitmapData = calloc(width * height * 4, sizeof(Byte));
	if (bitmapData == NULL)
	{
		return nil;
	}

	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	//	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
	context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow,
									colorspace, kCGImageAlphaPremultipliedLast);
	//	CGColorSpaceRelease(colorspace);

	if (context == NULL)
		// error creating context
		return nil;

	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextSaveGState(context);

	//	CGContextTranslateCTM(context, -region.origin.x, -region.origin.y);
	//	CGContextDrawImage(context, region, image);

	// Draw the image without scaling it to fit the region
	CGRect drawRegion;
	drawRegion.origin = CGPointZero;
	drawRegion.size.width = CGImageGetWidth(image);
	drawRegion.size.height = CGImageGetHeight(image);
	CGContextTranslateCTM(context,
						  -region.origin.x + (drawRegion.size.width - region.size.width),
						  -region.origin.y - (drawRegion.size.height - region.size.height));
	CGContextDrawImage(context, drawRegion, image);
	CGContextRestoreGState(context);

	// When finished, release the context
	CGContextRelease(context);

	// Now we can get a pointer to the image data associated with the bitmap context.

	NSData *data = [NSData dataWithBytes:bitmapData length:bitmapByteCount];
	free(bitmapData);

	return data;
}
