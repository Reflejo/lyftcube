#include "parser.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))

#pragma pack(push, 1)

typedef struct BitmapHeader {
    unsigned short type;
    unsigned int size;
    unsigned int reserved;
    unsigned int offset;
} BitmapHeader;

typedef struct BitmapInfo {
    unsigned int size;              // Header size in bytes
    int width, height;              // Width and height of image
    unsigned short planes;          // Number of colour planes
    unsigned short bits;            // Bits per pixel
    unsigned int compression;       // Compression type
    unsigned int imagesize;         // Image size in bytes
    int xresolution, yresolution;   // Pixels per meter
    unsigned int ncolours;          // Number of colours
    unsigned int importantcolours;  // Important colours
} BitmapInfo;

#pragma pack(pop)

// --- Misc helpers ----

char *binary(int n) {
    static char binary[8] = "xxxxxxxx";
    int i;
    for (i = 0; i < 8; i++) {
        binary[7 - i] = (n >> i) & 1 ? '1' : '0';
    }
    return binary;
}

int convert_to_4bits(int component) {
    return MIN(ceil(component / 2.0), 0b1111);
}

// --- Parsing helpers ----

int parse_durations(char *duration_path, struct Animation *animation) {
    FILE *file = fopen(duration_path, "rb");
    if (file == NULL) {
        fprintf(stderr, "Can't open file %s\n", duration_path);
        return 0;
    }

    fseek(file, 0, SEEK_END);
    int length = ftell(file);
    rewind(file);

    if (length != animation->frames_count) {
        fprintf(stderr, "Invalid durations length (%d)\n", length);
        return 0;
    }

    int i;
    for (i = 0; i < length; i++) {
        printf("Duration: %d\n", animation->frames[i].duration);
        fread(&animation->frames[i].duration, 1, 1, file);
    }

    fclose(file);
    return i;
}

int parse_bitmap(char *bitmap_path, struct Animation *animation) {
    BitmapHeader header;
    BitmapInfo infoHeader;

    FILE *file = fopen(bitmap_path, "rb");
    if (file == NULL) {
        fprintf(stderr, "Can't open file %s\n", bitmap_path);
        return 0;
    }

    if (fread(&header, 1, sizeof(BitmapHeader), file) != sizeof(BitmapHeader)) {
        fprintf(stderr, "Invalid bitmap file's header\n");
        fclose(file);
        return 0;
    }

    if (fread(&infoHeader, 1, sizeof(BitmapInfo), file) != sizeof(BitmapInfo)) {
        fprintf(stderr, "Invalid bitmap file's info header\n");
        fclose(file);
        return 0;
    }

    animation->frames_count = ceil(infoHeader.width / 8);
    animation->frames = malloc(sizeof(struct Frame) * animation->frames_count);

    fseek(file, header.offset, SEEK_SET);
    unsigned short colorBytes;
    int i = 0, bit = 0;
    for (i = 0; i < (infoHeader.width * infoHeader.height); i++) {
        if (fread(&colorBytes, 1, 2, file) != 2) {
            fprintf(stderr, "Error reading pixels, invalid bitmap file\n");
            break;
        }

        // We only support 16-bit BMPs, colors are represented by two bytes
        // as: r, g, b = 5 bits, 5 bits, 5 bits.
        unsigned char r = MIN(convert_to_4bits((colorBytes >> 10) & 0x1f), 10);
        unsigned char g = convert_to_4bits((colorBytes >> 5) & 0x1f);
        unsigned char b = convert_to_4bits((colorBytes >> 0) & 0x1f);

        int level = (i / infoHeader.width) / 8.0;
        int frame_index = (i % infoHeader.width) / 8.0;
        int x = (i % infoHeader.width) % 8;
        int y = (i / infoHeader.width) % 8;

        struct Frame *frame = &animation->frames[frame_index];
        for (bit = 0; bit < 4; bit++) {
            frame->cube[bit][level][y] |= ((r >> bit) & 1) << (7 - x);
            frame->cube[bit][level][y + 8] |= ((g >> bit) & 1) << (7 - x);
            frame->cube[bit][level][y + 16] |= ((b >> bit) & 1) << (7 - x);
        }
    }

    fclose(file);
    return 1;
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
struct Animation parse_animation(char *bitmap_path, char *delays_path) {
    struct Animation animation;
    animation.frames = NULL;

    if (parse_bitmap(bitmap_path, &animation) == 0) {
        fprintf(stderr, "Can't parse bitmap file %s\n", bitmap_path);
        return animation;
    }

    short *delays = malloc(sizeof(short) * animation.frames_count);
    if (parse_durations(delays_path, &animation) == 0) {
        fprintf(stderr, "Can't parse durations file %s\n", bitmap_path);
        animation.frames = NULL;
    }

    free(delays);
    return animation;
}
