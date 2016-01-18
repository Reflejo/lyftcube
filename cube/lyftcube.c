#include "animation.h"
#include "GPIO.h"

#include <sched.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct Animation animation;

void terminate(int signal) {
    printf("Terminating LED cube ...\n");
    restore_gpios();
    exit(EXIT_SUCCESS);
}

void restart(int signal) {
    char path[PATH_MAX + 1];
    if (animation.frames != NULL) {
        free(animation.frames);
    }

    if (!load_current_animation(&animation, path)) {
        restore_gpios();
        exit(EXIT_FAILURE);
    }

    printf("Loaded animation %s...\n", path);
}

int main(int argc, char *argv[]) {
    bool pretend = argc > 1 && (strcmp(argv[1], "-p") == 0);
    printf("Lyft LED cube starting ...\n");

    // Make sure we clean up the state after a CTRL+C
    signal(SIGINT, terminate);
    signal(SIGTERM, terminate);

    // Reload animation on SIGHUB
    signal(SIGHUP, restart);

    restart(0);
    if (animation.frames == NULL || animation.frames_count == 0) {
        fprintf(stderr, "Couldn't read animation file.\n");
        return EXIT_FAILURE;
    }

    // We need root to access GPIOS and scheduler.
    uid_t uid = getuid();
    if (setuid(0) == -1) {
        fprintf(stderr, "Incorrect binary permissions, (set 2750)\n");
        return EXIT_FAILURE;
    }

    struct sched_param schedp;
    schedp.sched_priority = 99;
    sched_setscheduler(0, SCHED_FIFO, &schedp);

    if (!initialize_gpios()) {
        printf("Initialization error\n");
        return EXIT_FAILURE;
    }

    setuid(uid);
    multiplex(&animation, pretend);
    free(animation.frames);
    return EXIT_SUCCESS;
}
