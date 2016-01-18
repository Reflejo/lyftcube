#include <CoreGraphics/CGImage.h>
#include <ImageIO/CGImageSource.h>
#include <ImageIO/CGImageDestination.h>
#include <ImageIO/CGImageProperties.h>
#include <MobileCoreServices/UTCoreTypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "helpers.h"

#define MAX_FRAMES  6048

typedef uint8_t CubeFrame[8 * 8 * 8 * 3];

int currentFrame = 0;
double *delays;
CubeFrame *frames;

void startAnimation() {
    frames = calloc(sizeof(CubeFrame), MAX_FRAMES);
    delays = calloc(sizeof(double), MAX_FRAMES);
    currentFrame = 0;
}

void endAnimation() {
    free(frames);
    free(delays);
    currentFrame = 0;
}

void saveAnimation(CFURLRef URL) {
    CFStringRef gifKeys[1] = { kCGImagePropertyGIFHasGlobalColorMap };
    CFTypeRef gifValues[1] = { kCFBooleanFalse };
    CFStringRef imageKeys[1] = { kCGImagePropertyGIFDictionary };
    CFTypeRef imageValues[1] = {
        CFDictionaryCreate(NULL, (const void **)gifKeys, gifValues, 1,
                           &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)
    };

    CFDictionaryRef properties = CFDictionaryCreate(NULL, (const void **)imageKeys, imageValues, 1,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(URL, kUTTypeGIF, currentFrame, NULL);
    CGImageDestinationSetProperties(destination, properties);
    CFRelease(properties);

    for (int i = 0; i < currentFrame; i++) {
        CFStringRef gifKeys[1] = { kCGImagePropertyGIFDelayTime };
        CFTypeRef gifValues[1] = { CFNumberCreate(NULL, kCFNumberDoubleType, &delays[i]) };
        CFStringRef imageKeys[1] = { kCGImagePropertyGIFDictionary };
        CFTypeRef imageValues[1] = {
            CFDictionaryCreate(NULL, (const void **)gifKeys, gifValues, 1,
                               &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)
        };

        CFDictionaryRef properties = CFDictionaryCreate(NULL, (const void **)imageKeys, imageValues, 1,
            &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);;

        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNone;
        CGDataProviderRef data = CGDataProviderCreateWithData(NULL, frames[i], sizeof(CubeFrame), NULL);
        CGImageRef imageRef = CGImageCreate(8, 64, 8, 8 * 3, 8 * 3, CGColorSpaceCreateDeviceRGB(),
                                            bitmapInfo, data, NULL, false, kCGRenderingIntentDefault);
        CGImageDestinationAddImage(destination, imageRef, properties);

        CFRelease(data);
        CFRelease(imageRef);
        CFRelease(properties);
        CFRelease(imageValues[0]);
        CFRelease(gifValues[0]);
    }

    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    CFRelease(imageValues[0]);
    endAnimation();
}

void clean() {
    memset(&frames[currentFrame], 0, sizeof(CubeFrame));
}

void LED(int level, int row, int column, uint8_t red, uint8_t green, uint8_t blue) {
    level = MAX(MIN(level, 7), 0);

    int x = MAX(MIN(column, 7), 0);
    int y = MAX(MIN(row, 7), 0) + (level * 8);

    frames[currentFrame][(x * 3) + (y * 8 * 3)] = ((double)red / 15) * 255;
    frames[currentFrame][(x * 3) + (y * 8 * 3) + 1] = ((double)green / 15) * 255;
    frames[currentFrame][(x * 3) + (y * 8 * 3) + 2] = ((double)blue / 15) * 255;
}

void commitFrame(int delay) {
    delays[currentFrame++] = (double)MAX(delay, 0) / 1000;
    memcpy(frames[currentFrame], frames[currentFrame - 1], sizeof(CubeFrame));
}

unsigned int randrange(int min, int max) {
    return arc4random_uniform(max - min) + min;
}