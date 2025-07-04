/*
 * JSON Parser
 * 
 * This module provides utility functions for extracting values from JSON-formatted 
 * WebSocket messages received from cryptocurrency exchanges.
 * 
 * Features:
 *  - Extracts quoted string values from JSON messages.
 *  - Extracts numeric values from JSON messages.
 *  - Parses Bitfinex ticker price from an array-based JSON response.
 *  - Extracts currency symbols from Huobi's WebSocket channel format.
 * 
 * Dependencies:
 *  - Standard C libraries (string.h, stdlib.h).
 * 
 * Usage:
 *  - Called by `exchange_websocket.c` to process market data in WebSocket responses.
 *  - Helps transform raw WebSocket JSON messages into structured price and timestamp data.
 * 
 * Created: 3/7/2025
 * Updated: 4/14/2025
 */

#include "json_parser.h"
#include <string.h>
#include <stdlib.h>

/* Extract a quoted value from JSON using key */
int extract_order_data(const char *json, const char *key, char *dest, size_t dest_size) {
    const char *pos = strstr(json, key);
    if (!pos) return 0;
    pos += strlen(key);

    if (*pos == '"') pos++;

    size_t len = 0;
    while (pos[len] && pos[len] != '"' && pos[len] != ',' && pos[len] != '}') {
        len++;
    }

    if (len >= dest_size) len = dest_size - 1;
    memcpy(dest, pos, len);
    dest[len] = '\0';

    return (len > 0);
}

/* Extract a quoted value from JSON array field using key */
int extract_array_field(const char *json, const char *key, char *dest, size_t dest_size, size_t index) {
    const char *pos = strstr(json, key);
    if (!pos) return 0;
    pos += strlen(key);

    /* Skip index * 2 + 1 quotes to reach the desired quoted value */
    size_t quotes_to_skip = index * 2 + 1;
    size_t quotes_found = 0;
    while (*pos && quotes_found < quotes_to_skip) {
        if (*pos == '"') {
            quotes_found++;
        }
        pos++;
    }
    /* Check if we found enough quotes */
    if (quotes_found < quotes_to_skip) return 0;
    
    size_t len = strcspn(pos, "\"");
    if (len >= dest_size) len = dest_size - 1;
    memcpy(dest, pos, len);
    dest[len] = '\0';

    if (strcmp(dest, "\0") == 0)
        return 0;
    return 1;
}

/* Extract a numeric (unquoted) value from JSON using key */
int extract_numeric(const char *json, const char *key, char *dest, size_t dest_size) {
    const char *pos = strstr(json, key);
    if (!pos) return 0;
    pos += strlen(key);
    pos += strspn(pos, " :\"");
    size_t len = strspn(pos, "0123456789.-");
    if (len >= dest_size) len = dest_size - 1;
    memcpy(dest, pos, len);
    dest[len] = '\0';
    return 1;
}

/* Extract Bitfinex ticker price from an array message */
int extract_bitfinex_price(const char *json, char *dest, size_t dest_size) {
    const char *start = strchr(json, '[');
    if (!start) return 0;
    start++;
    int count = 0;
    const char *priceStart = NULL;
    for (const char *p = start; *p; p++) {
        if (*p == ',') {
            if (++count == 7) {
                priceStart = p + 1;
                break;
            }
        }
    }
    if (!priceStart) return 0;
    size_t len = strcspn(priceStart, ",]");
    if (len >= dest_size) len = dest_size - 1;
    memcpy(dest, priceStart, len);
    dest[len] = '\0';
    return 1;
}

/* Extract currency from Huobi channel string */
int extract_huobi_currency(const char *json, char *dest, size_t dest_size) {
    const char *ch_pos = strstr(json, "\"ch\":\"market.");
    if (!ch_pos) {
        strncpy(dest, "unknown", dest_size);
        if (dest_size) dest[dest_size - 1] = '\0';
        return 0;
    }

    ch_pos += strlen("\"ch\":\"market.");
    const char *end = strchr(ch_pos, '.');  // Stops at first '.' after symbol
    if (!end) {
        strncpy(dest, "unknown", dest_size);
        if (dest_size) dest[dest_size - 1] = '\0';
        return 0;
    }

    size_t len = end - ch_pos;
    if (len >= dest_size) len = dest_size - 1;

    memcpy(dest, ch_pos, len);
    dest[len] = '\0';

    return 1;
}
