#include "parser.h"

#include <gif_lib.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))
#define HEIGHT      64
#define WIDTH       8

// --- Misc helpers ----

char *binary(int n) {
    static char binary[8] = "xxxxxxxx";
    int i;
    for (i = 0; i < 8; i++) {
        binary[7 - i] = (n >> i) & 1 ? '1' : '0';
    }
    return binary;
}

uint8_t convert_to_4bits(int component) {
    double percent = (double)component / 255.0;
    return MIN(ceil(0b11111 * percent), 0b1111);
}

uint16_t find_delay_time(SavedImage *image, int previous_delay) {
    ExtensionBlock *blocks = image->ExtensionBlocks;

    GraphicsControlBlock GCB;
    for (uint16_t i = 0; i < image->ExtensionBlockCount; i++) {
        ExtensionBlock block = blocks[i];
        if (block.Function == GRAPHICS_EXT_FUNC_CODE) {
            DGifExtensionToGCB(block.ByteCount, block.Bytes, &GCB);
            return GCB.DelayTime;
        }
    }

    return -1;
}

// --- Exposed functions ----

/**
 * Prints an array of 24 bytes containing a level of the LED cube for every
 * color (8 x 3). Use for debug only.
 *
 * - parameter buffer: An array of 24 bytes; each one containing a line of a
 *                     LED cube level.
 */
void dump_buffer(unsigned char *buffer) {
    int i, color_index;

    printf("===R====\t===G====\t===B====\n");
    for (i = 7; i >= 0; i--) {
        for (color_index = 0; color_index < 3; color_index++) {
            printf("%s\t", binary(buffer[i + (color_index * 8)]));
        }
        printf("\n");
    }
}

/**
 * Parse animation frames from a multi-frame animated GIF file.
 *
 * - parameter gif_path:      A path to a multiframe GIF file containing all cube
 *                            levels one on top of each other.
 */
bool parse_gif(char *gif_path, struct Animation *animation) {
    GifFileType *gif = DGifOpenFileName(gif_path, NULL);
    if (gif == NULL || DGifSlurp(gif) != GIF_OK) {
        fprintf(stderr, "Error reading GIF file %s.\n", gif_path);
        return false;
    }

    uint16_t frame_count = gif->ImageCount;
    animation->frames_count = frame_count;
    animation->frames = calloc(frame_count, sizeof(struct Frame));

    SavedImage *frames = gif->SavedImages;
    uint16_t delay = 3;

    if (gif->SWidth != WIDTH || gif->SHeight != HEIGHT) {
        fprintf(stderr, "Invalid GIF size %dx%d\n", gif->SWidth, gif->SHeight);
        return false;
    }

    GifByteType bytes[HEIGHT * WIDTH] = {0};
    for (uint16_t frame_index = 0; frame_index < frame_count; frame_index++) {
        SavedImage imageframe = frames[frame_index];
        GifImageDesc frame_desc = imageframe.ImageDesc;
        uint8_t top = frame_desc.Top, left = frame_desc.Left;
        uint8_t height = frame_desc.Height, width = frame_desc.Width;

        // Setup animation frame
        struct Frame *frame = &animation->frames[frame_index];
        frame->duration = find_delay_time(&imageframe, delay);

        for (uint16_t y = top, i = 0; y < top + height; y++) {
            for (uint8_t x = left; x < left + width; x++) {
                GifByteType color_index = imageframe.RasterBits[i++];
                bytes[x + (y * 8)] = color_index;
            }
        }

        ColorMapObject *colorMap = frame_desc.ColorMap ?: gif->SColorMap;
        GifColorType *colors = colorMap->Colors;
        for (uint8_t abs_y = 0; abs_y < HEIGHT; abs_y++) {
            for (uint8_t x = 0; x < WIDTH; x++) {
                GifByteType color_index = bytes[x + (abs_y * WIDTH)];
                uint8_t r = MIN(convert_to_4bits(colors[color_index].Red), 11);
                uint8_t g = convert_to_4bits(colors[color_index].Green);
                uint8_t b = convert_to_4bits(colors[color_index].Blue);

                uint8_t level = abs_y / 8;
                uint8_t y = abs_y % 8;
                for (uint8_t bit = 0; bit < 4; bit++) {
                    frame->cube[bit][level][y] |= ((r >> bit) & 1) << (7 - x);
                    frame->cube[bit][level][y + 8] |= ((g >> bit) & 1) << (7 - x);
                    frame->cube[bit][level][y + 16] |= ((b >> bit) & 1) << (7 - x);
                }
            }
        }
    }

    DGifCloseFile(gif, NULL);
    return true;
}
