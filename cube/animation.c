#include "animation.h"
#include "GPIO.h"
#include "parser.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


#define DUTY_DELAY_NS    124
#define ANIMATION_FILE   "/opt/lyft/lyftcube/cube/animations/current_animation"


const uint8_t levels[8] = {
    LEVEL1, LEVEL2, LEVEL3, LEVEL4, LEVEL5, LEVEL6, LEVEL7, LEVEL8
};

/** Bit angle modulation works this way: we set a brightness between [0, 15]
 *  (4 bits), each bit of that number defines if the color should be on for
 *  that bit cycle or not; when the cycle is over, we move to the next bit
 *  position according to the following array,
 *
 *  For example if brightness on red is 9 (binary: 1001) we'll:
 *  - Turn red ON while we cycle the first bit (1 pass)
 *  - Turn red OFF while we cycle the second bit (2 passes)
 *  - Turn red OFF while we cycle the third bit (4 passes)
 *  - Turn red ON while we cycle the fourth bit (8 passes)
 */
static const uint8_t BAM[] = {0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3};

/**
 * Parses the animation that should be played next based on the content of the
 * file at `ANIMATION_FILE`. The content of the new animation struct will be
 * stored into the given animation pointer.
 *
 * - parameter animation: The pointer where the parsed animation will be stored
 * - parameter path:      A pointer that will contain the path of the loaded
 *                        animation when the parsing is successful.
 */
bool load_current_animation(struct Animation *animation, char *path) {
    FILE *file = fopen(ANIMATION_FILE, "r");
    if (file == NULL) {
        fprintf(stderr, "Can't open animation file %s", ANIMATION_FILE);
        return false;
    }

    // Read current animation path from ANIMATION_FILE
    char gif_path[PATH_MAX + 1];
    if (fgets(gif_path, PATH_MAX, file) == NULL) {
        fprintf(stderr, "Invalid animation path in %s", ANIMATION_FILE);
        return false;
    }

    // Trim newlines from path.
    char *pos;
    if ((pos = strchr(gif_path, '\n')) != NULL) {
        *pos = '\0';
    }

    animation->frames = NULL;
    animation->frames_count = 0;
    if (parse_gif(gif_path, animation) == 0) {
        return false;
    }

    strcpy(path, gif_path);
    return true;
}

/**
 * Performs given animation by multiplexing cube levels. It uses bit angle
 * modulation to control the brightness of each color.
 *
 * - parameter animation: The animation to multiplex including all frames.
 * - parameter pretend:   When true we'll print on the screen every LED
 *                        level using a slowed-down BAM rate (debug only).
 */
void multiplex(struct Animation *animation, bool pretend) {
    uint8_t level = 0;
    uint8_t BAM_index = 0;
    uint32_t frame_index = 0;
    uint32_t *frame_count = &animation->frames_count;
    uint16_t frame_delay = 0;

    struct timespec sleep_time;
    sleep_time.tv_sec = pretend ? 1 : 0;
    sleep_time.tv_nsec = 1000 * (long)(DUTY_DELAY_NS);

    while (1) {
        struct Frame *frame = &animation->frames[frame_index % *frame_count];
        int bit = BAM[BAM_index];

        if (pretend) {
            printf("=========== bit: %d, level: %d ============\n", bit, level);
            dump_buffer(frame->cube[bit][level]);
        } else {
            bcm2835_spi_writenb((char *)frame->cube[bit][level], 24);

            // Turn off previous level and turn on the current one.
            bcm2835_gpio_set(levels[level == 0 ? 7 : level - 1]);
            bcm2835_gpio_clr(levels[level]);
        }

        // Move to the next level (or cycle when the 8th level is reached),
        // at that point we also increment the BAM index to start the next
        // BAM cycle.
        if (++level == 8) {
            level = 0;

            if (++BAM_index == 0b1111) {
                BAM_index = 0;

                if (++frame_delay >= frame->duration) {
                    frame_delay = 0;
                    frame_index = (frame_index + 1) % *frame_count;
                }
            }
        }

        nanosleep(&sleep_time, NULL);
    }
}
