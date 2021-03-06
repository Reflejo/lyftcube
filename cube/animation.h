#ifndef _LEDSH_
#define _LEDSH_

#include <stdbool.h>
#include <stdint.h>
#include <linux/limits.h>

/**
 * This matrix represents the current state of the LED cube, the first
 * dimension represents the bit on the Bit Angle Modulation cycle, the
 * second dimension represents levels (8 levels) from top to bottom. The third
 * dimension holds the state of each level as follows:
 *
 * If you looked down the LED cube from the top positions are:
 *
 * 00 01 02 03 04 05 06 07 <- 1st array's element
 * 08 09 10 11 12 13 14 15 <- 2nd array's element
 * 16 17 18 19 20 21 22 23 <- 3rd array's element
 * 24 25 26 27 28 29 30 31 <- 4th array's element
 * 32 33 34 35 36 37 38 39 <- 5th array's element
 * 40 41 42 43 44 45 46 47 <- 6th array's element
 * 48 49 50 51 52 53 54 55 <- 7th array's element
 * 56 57 58 59 60 61 62 63 <- 8th array's element
 *
 * .. and this same schema goes on for the 3 colors: hence 24 elements. Green
 * would be (ith + 8) and Blue (ith + 16).
 *
 */
typedef uint8_t LEDCube[4][8][24];

struct Frame {
    LEDCube cube;
    uint16_t duration;
};

struct Animation {
    struct Frame *frames;
    uint32_t frames_count;
};

/// Array of LEDs levels where i=0 is the bottom-most and 8 is the top-most
extern const uint8_t levels[8];

/**
 * Performs given animation by multiplexing cube levels. It uses bit angle
 * modulation to control the brightness of each color.
 *
 * - parameter animation: The animation to multiplex including all frames.
 * - parameter pretend:   When true we'll print on the screen every LED
 *                        level using a slowed-down BAM rate (debug only).
 */
void multiplex(struct Animation *animation, bool pretend);

/**
 * Parses the animation that should be played next based on the content of the
 * file at `ANIMATION_FILE`. The content of the new animation struct will be
 * stored into the given animation pointer.
 *
 * - parameter animation: The pointer where the parsed animation will be stored
 * - parameter path:      A pointer that will contain the path of the loaded
 *                        animation when the parsing is successful.
 */
bool load_current_animation(struct Animation *animation, char *path);

#endif
