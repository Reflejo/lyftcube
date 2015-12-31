#include "GPIO.h"
#include "parser.h"

#include <sched.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void terminate(int signal) {
    printf("Terminating LED cube ...\n");
    restore_gpios();
    exit(0);
}

int main(int argc, char *argv[]) {
    bool pretend = argc > 1 && (strcmp(argv[1], "-p") == 0);
    printf("Lyft LED cube starting ...\n");

    // Make sure we clean up the state after a CTRL+C
    signal(SIGINT, terminate);

    struct Animation animation = parse_animation("hola.bmp", "delays");
    if (animation.frames == NULL) {
        exit(1);
    }

    struct sched_param schedp;
    schedp.sched_priority = 99;
    sched_setscheduler(0, SCHED_FIFO, &schedp);

    if (!initialize_gpios()) {
        printf("Initialization error\n");
        return 1;
    }

    multiplex_levels(animation, pretend);
    return 0;
}
