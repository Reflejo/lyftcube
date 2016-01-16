#include <asyncd/asyncd.h>

bool list_animations(ad_http_t *http, char *name, char **body, size_t *size);

bool animation(ad_http_t *http, char *name, char **body, size_t *size);

bool play_animation(ad_http_t *http, char *name, char **body, size_t *size);

bool upload(ad_http_t *http, char *name, char **body, size_t *size);

bool start(ad_http_t *http, char *name, char **body, size_t *size);

bool stop(ad_http_t *http, char *name, char **body, size_t *size);
