#include <asyncd/asyncd.h>
#include <stdio.h>
#include "endpoints.h"

#define ROUTES_COUNT    5

static char *error_response = "ERROR";

struct Route {
    const char *method;
    const char *uri;
    bool (*function)(ad_http_t *http, char *id, char **body, size_t *size);
};


// ----------- Handler -----------

int api_handler(short event, ad_conn_t *conn, void *userdata) {
    if (event & AD_EVENT_READ && ad_http_get_status(conn) == AD_HTTP_REQ_DONE)
    {
        struct Route *routes = (struct Route *)userdata;
        ad_http_t *http = (ad_http_t *)ad_conn_get_extra(conn);
        bool response_ok = false;
        char *body = error_response;
        size_t body_size = 5;

        for (uint8_t i = 0; i < ROUTES_COUNT; i++) {
            struct Route route = routes[i];
            size_t uri_len = strlen(route.uri);
            if (strcmp(route.method, http->request.method) == 0 &&
                strncmp(route.uri, http->request.uri, uri_len) == 0)
            {
                char *id = strlen(http->request.uri) > uri_len ?
                    &http->request.uri[uri_len] : NULL;
                if (id != NULL) {
                    qstrreplace("sr", id, "%20", " ");
                }

                response_ok = route.function(http, id, &body, &body_size);
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
    struct Route routes[ROUTES_COUNT] = {
        {"POST", "/animation/upload/", upload},
        {"POST", "/animation/play/", play_animation},
        {"GET", "/animation/", animation},
        {"POST", "/start", start},
        {"POST", "/stop", stop},
    };

    ad_server_t *server = ad_server_new();
    ad_server_set_option(server, "server.port", "1337");
    ad_server_register_hook(server, ad_http_handler, NULL);
    ad_server_register_hook(server, api_handler, &routes);
    return ad_server_start(server);
}
