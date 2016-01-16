#ifndef _PARSERH_
#define _PARSERH_

#include "animation.h"

/**
 * Parse animation frames from a multi-frame animated GIF file.
 *
 * - parameter gif_path:      A path to a multiframe GIF file containing all cube
 *                            levels one on top of each other.
 */
bool parse_gif(char *gif_path, struct Animation *animation);

/**
 * Prints an array of 24 bytes containing a level of the LED cube for every
 * color (8 x 3). Use for debug only.
 *
 * - parameter buffer: An array of 24 bytes; each one containing a line of a
 *                     LED cube level.
 */
void dump_buffer(unsigned char *buffer);

#endif
