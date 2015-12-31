#ifndef _PARSERH_
#define _PARSERH_

#include "leds.h"

/**
 * Parse animation frames from 16-bits bitmap file and durations from a binary
 * file.
 *
 * - parameter bitmap_path: A path to a 16-bits bitmap file containing all cube
 *                          levels one on top of each other and every anymation
 *                          frame next to the other, this means that the image
 *                          size should be h: 8 x 8 and w: 8 x frames_count.
 * - parameter duration_path: A path to a binary file containing 2 bytes
 *                            representing the duration of each frame; hence
 *                            the file size must be frames_count x 2
 */
struct Animation parse_animation(char *bitmap_path, char *duration_path);

/**
 * Prints an array of 24 bytes containing a level of the LED cube for every
 * color (8 x 3). Use for debug only.
 *
 * - parameter buffer: An array of 24 bytes; each one containing a line of a
 *                     LED cube level.
 */
void dump_buffer(unsigned char *buffer);

#endif
