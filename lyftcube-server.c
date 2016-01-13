#include <asyncd/asyncd.h>
#include <dirent.h>
#include <fcntl.h>
#include <linux/limits.h>
#include <stdio.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <unistd.h>

#define ANIMATIONS_PATH             "/opt/lyft/lyftcube/animations/"
#define CURRENT_ANIMATION_FILE      ANIMATIONS_PATH "current_animation"
#define MAX_UPLOAD_LENGTH           1024 * 1024 * 10
#define MAX_RESPONSE                2048
#define MAX_FILES_LIST              100

static char *error_response = "ERROR";

struct Route {
    const char *method;
    const char *uri;
    bool (*function)(ad_http_t *http, char *name, char **body, size_t *size);
};

// ----------- Helper functions -----------

char *animation_path(char *name) {
    static char path[PATH_MAX];
    static char finalpath[PATH_MAX];
    snprintf(path, sizeof(path) - 1, "%s%s.gif", ANIMATIONS_PATH, name);
    realpath(path, finalpath);
    if (strncmp(finalpath, ANIMATIONS_PATH, strlen(ANIMATIONS_PATH)) == 0) {
        return finalpath;
    }

    return NULL;
}

off_t animation_size(char *name) {
    struct stat stats;
    if (stat(animation_path(name), &stats) != 0) {
        return 0;
    }

    return stats.st_size;
}

// ----------- HTTP route functions -----------

bool list_animations(ad_http_t *http, char *name, char **body, size_t *size) {
    printf("Listing animations on %s\n", ANIMATIONS_PATH);

    DIR *directory = opendir(ANIMATIONS_PATH);
    if (directory == NULL) {
        return false;
    }

    *size = 0;
    *body = calloc(sizeof(char), MAX_FILES_LIST * PATH_MAX);
    for (uint8_t i = 0; i < MAX_FILES_LIST; i++) {
        struct dirent *entity = readdir(directory);
        if (entity == NULL) {
            break;
        }

        size_t name_len = strlen(entity->d_name);
        if (name_len > 4 && !strcmp(entity->d_name + name_len - 4, ".gif")) {
            char animation[name_len - 3];
            snprintf(animation, name_len - 3, "%s", entity->d_name);

            int total = sprintf(*body + *size, "%s,%s,%jd\n",
                animation, animation, animation_size(animation));
            *size += total;
        }
    }

    closedir(directory);
    return true;
}

bool animation(ad_http_t *http, char *name, char **body, size_t *size) {
    if (name == NULL) {
        return list_animations(http, name, body, size);
    }

    FILE *file = fopen(animation_path(name), "rb");
    if (file == NULL) {
        return false;
    }

    fseek(file, 0L, SEEK_END);
    size_t file_size = ftell(file);
    rewind(file);

    *body = malloc(sizeof(char) * file_size);
    *size = file_size;

    fread(*body, 1, file_size, file);
    fclose(file);
    return true;
}

bool play_animation(ad_http_t *http, char *name, char **body, size_t *size) {
    char *path = animation_path(name);
    if (path == NULL) {
        printf("Invalid animation name given\n");
        return false;
    }

    printf("Playing animation %s\n", path);

    FILE *file = fopen(CURRENT_ANIMATION_FILE, "wb");
    if (file == NULL) {
        return false;
    }

    fwrite(path, sizeof(char), strlen(path), file);
    fclose(file);

    system("killall -HUP lyftcube");

    *size = strlen(name);
    *body = calloc(sizeof(char), *size + 1);
    memcpy(*body, name, *size);

    return true;
}

bool upload(ad_http_t *http, char *name, char **body, size_t *size) {
    if (http->request.bodyin > MAX_UPLOAD_LENGTH) {
        return false;
    }

    char *path = animation_path(name);
    FILE *file = fopen(path, "wb");
    if (file == NULL) {
        return false;
    }

    printf("Upload animation %s (sized %zu)...\n", path, http->request.bodyin);

    char data[http->request.bodyin];
    evbuffer_copyout(http->request.inbuf, data, http->request.bodyin);
    fwrite(data, 1, http->request.bodyin, file);
    fclose(file);

    return play_animation(http, name, body, size);
}

// ----------- Handler -----------

int api_handler(short event, ad_conn_t *conn, void *userdata) {
    if (event & AD_EVENT_READ && ad_http_get_status(conn) == AD_HTTP_REQ_DONE)
    {
        struct Route *routes = (struct Route *)userdata;
        ad_http_t *http = (ad_http_t *)ad_conn_get_extra(conn);
        bool response_ok = false;
        char *body = error_response;
        size_t body_size = 0;

        for (uint8_t i = 0; i < 3; i++) {
            struct Route route = routes[i];
            size_t uri_len = strlen(route.uri);
            if (strcmp(route.method, http->request.method) == 0 &&
                strncmp(route.uri, http->request.uri, uri_len) == 0)
            {
                char *name = strlen(http->request.uri) > uri_len ?
                    &http->request.uri[uri_len] : NULL;
                if (name != NULL) {
                    qstrreplace("sr", name, "%20", " ");
                }

                response_ok = route.function(http, name, &body, &body_size);
                break;
            }
        }

        int code = response_ok ? 200 : 500;
        ad_http_response(conn, code, "text/plain", body, body_size);
        if (body != error_response) {
            free(body);
        }

        return AD_CLOSE;
    }

    return AD_OK;
}

// ----------- Main -----------

int main(int argc, char **argv) {
    struct Route routes[3] = {
        {"POST", "/animation/upload/", upload},
        {"POST", "/animation/play/", play_animation},
        {"GET", "/animation/", animation},
    };

    ad_server_t *server = ad_server_new();
    ad_server_set_option(server, "server.port", "1337");
    ad_server_register_hook(server, ad_http_handler, NULL);
    ad_server_register_hook(server, api_handler, &routes);
    return ad_server_start(server);
}
