#include <CoreGraphics/CGImage.h>
#include <sys/param.h>

/**
 Sets all the LEDs to off.
 */
void clean();

/**
 Sets the LED at the given position to the colors defined on the RGB values.

 @param row    The y coordinate of the 2-D level (0-7)
 @param level  The level on the LED cube (0-7) from bottom to top
 @param column The x coordinate of the 2-D level (0-7)
 @param red    The red component (0-255)
 @param green  The green component (0-255)
 @param blue   The blue component (0-255)
 */
void LED(int level, int row, int column, uint8_t red, uint8_t green, uint8_t blue);

/**
 Saves the current frame and move to the next frame

 @param delay The delay that will be set for the stored frame.
 */
void commitFrame(int delay);

/**
 Returns a random number from [min, max)

 @param min The minimum value on the random range (included)
 @param max The maximum value on the random range (not included)

 @return a random number between [min, max)
 */
unsigned int randrange(int min, int max);

/**
 Allocs the buffers and prepares the memory for an animation (you *must* call saveAnimation or endAnimation).
 */
void startAnimation();

/**
 Frees the alloc'ed memory and resets the frames.
 */
void endAnimation();

/**
 Saves the current animation into a file in the given path, this also frees the alloc'ed memory.

 @param URL The URL path of the file where the animation (GIF) will be stored.
 */
void saveAnimation(CFURLRef URL);
