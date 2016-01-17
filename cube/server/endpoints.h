#include <asyncd/asyncd.h>

/**
 * These functions contain the logic to server each specific endpoint, every
 * one of these functions take the parameters described as follows:
 *
 * - parameter http: The http object containing request and response
 * - parameter id:   The requested animation's id (if applicable) or NULL
 * - parameter body: A pointer to a string that will contain the body of the 
 *                   response. Note that callers have to free it when done,
 *                   when the body is NULL, the body will be inferred as 
 *                   'ERROR' and the siez won't be used.
 * - parameter size: A pointer to an integer that will contain the size of
 *                   the response body
 */

/**
 * List all GIF files (animations) found in the animations directory, the 
 * format of the response is a comma separated list as:
 * name,id,size
 */
bool list_animations(ad_http_t *http, char *id, char **body, size_t *size);

/**
 * Returns one specific GIF file if `id` is given or fallback to 
 * list_animations if not.
 */
bool animation(ad_http_t *http, char *id, char **body, size_t *size);

/**
 * Plays the animation with the given id.
 */
bool play_animation(ad_http_t *http, char *id, char **body, size_t *size);

/**
 * Create (or edit) an animation with the content of the request body (it
 * should be a GIF file). The animation id will match the name and the file
 * will be stored into the animations directory.
 */
bool upload(ad_http_t *http, char *name, char **body, size_t *size);

/**
 * Starts the cube. If it's already started this is a nop.
 */
bool start(ad_http_t *http, char *id, char **body, size_t *size);

/**
 * Shut downs the cube daemon. If it's not running this is a nop.
 */
bool stop(ad_http_t *http, char *id, char **body, size_t *size);
