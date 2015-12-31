#include "GPIO.h"
#include "leds.h"
#include "parser.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define DUTY_DELAY_NS       124

const int levels[8] = {
    LEVEL1, LEVEL2, LEVEL3, LEVEL4, LEVEL5, LEVEL6, LEVEL7, LEVEL8
};

/// Bit angle modulation works this way: we set a brightness between [0, 15]
/// (4 bits), each bit of that number defines if the color should be on for
/// that bit or not; then we cycle the bit positions following this array,
///
/// For example if brightness on red is 9 (binary: 1001) we'll:
/// - Turn red ON while we cycle the first bit (1 pass)
/// - Turn red OFF while we cycle the second bit (2 passes)
/// - Turn red OFF while we cycle the third bit (4 passes)
/// - Turn red ON while we cycle the fourth bit (8 passes)
static const int BAM[] = {0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3};

/**
 * Performs given animation by multiplexing cube levels. It uses bit angle
 * modulation to control the brightness of each color.
 *
 * - parameter animation: The animation to multiplex including all frames.
 * - parameter pretend:   When true we'll print on the screen every LED
 *                        level using a slowed-down BAM rate (debug only).
 */
void multiplex_levels(struct Animation animation, bool pretend) {
    printf("Frames count: %d\n", animation.frames_count);

    int level = 0;
    int BAM_index = 0;
    int frame_index = 0;

    struct timespec sleep_time;
    sleep_time.tv_sec = pretend ? 1 : 0;
    sleep_time.tv_nsec = 1000 * (long)(DUTY_DELAY_NS);

    while (1) {
        struct Frame *frame = &animation.frames[frame_index];
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

            if (++BAM_index == 15) {
                BAM_index = 0;
                frame_index = (frame_index + 1) % animation.frames_count;
            }
        }

        nanosleep(&sleep_time, NULL);
    }
}
