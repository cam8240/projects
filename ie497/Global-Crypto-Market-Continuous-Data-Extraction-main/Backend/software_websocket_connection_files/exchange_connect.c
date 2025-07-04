/*
 * Exchange Connection
 * 
 * This module is responsible for establishing WebSocket connections to various 
 * cryptocurrency exchanges. It provides individual functions for connecting to 
 * each supported exchange.
 * 
 * Features:
 *  - Initializes WebSocket connections for real-time market data.
 *  - Supports multiple cryptocurrency exchanges.
 *  - Uses libwebsockets to establish secure connections.
 * 
 * Dependencies:
 *  - libwebsockets: Handles WebSocket communication.
 *  - Standard C libraries (stdio, stdlib, string).
 * 
 * Usage:
 *  - Used by `main.c` to establish WebSocket connections.
 *  - Called by `exchange_reconnect.c` to reconnect upon failure.
 * 
 * Created: 3/11/2025
 * Updated: 5/12/2025
 */

#include "exchange_connect.h"
#include "exchange_websocket.h"
#include "utils.h"
#include <libwebsockets.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

/* Global context reference from main.c */
extern struct lws_context *context;


/* Thread function to connect to each exchange */
void* connect_to_exchange_thread(void* exchange_name) {
    const char* exchange = (const char*) exchange_name;

    if (strcmp(exchange, "binance") == 0) {
        int total_symbols_binance = count_symbols_in_file("currency_text_files/binance_currency_ids_trades.txt");
        int num_chunks_binance = (total_symbols_binance + 99) / 100;
        for (int i = 0; i < num_chunks_binance; i++) {
            connect_to_binance(i);
            usleep(50000);
        }   
    } else if (strcmp(exchange, "coinbase") == 0) {
        connect_to_coinbase();
        usleep(50000);
    } else if (strcmp(exchange, "kraken") == 0) {
        connect_to_kraken();
        usleep(50000);
    } else if (strcmp(exchange, "huobi") == 0) {
        int total_symbols_huobi = count_symbols_in_file("currency_text_files/huobi_currency_ids.txt");
        int num_chunks_huobi = (total_symbols_huobi + 99) / 100;
        for (int i = 0; i < num_chunks_huobi; i++) {
            connect_to_huobi(i);
            usleep(50000);
        }    
    } else if (strcmp(exchange, "okx") == 0) {
        int total_symbols_okx = count_symbols_in_file("currency_text_files/okx_currency_ids.txt");
        int num_chunks_okx = (total_symbols_okx + 99) / 100;
        for (int i = 0; i < num_chunks_okx; i++) {
            connect_to_okx(i);
            usleep(50000);
        }    
    }

    return NULL;
}

/* Function to start connections to all exchanges in parallel */
void start_exchange_connections() {
    pthread_t threads[5];  // Assuming 5 exchanges
    const char* exchanges[] = {"binance", "coinbase", "kraken", "huobi", "okx"};

    // Loop through all exchanges and create a new thread for each one
    for (int i = 0; i < 5; i++) {
        if (pthread_create(&threads[i], NULL, connect_to_exchange_thread, (void*)exchanges[i]) != 0) {
            printf("[ERROR] Failed to create thread for %s\n", exchanges[i]);
        }
    }

    // Wait for all threads to complete
    for (int i = 0; i < 5; i++) {
        pthread_join(threads[i], NULL);
    }
}


void connect_to_binance(int index) {
    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = "stream.binance.us";
    ccinfo.port = 9443;
    ccinfo.path = "/ws";
    ccinfo.host = "stream.binance.us";
    ccinfo.origin = "stream.binance.us";

    static char protocol_name[32];
    snprintf(protocol_name, sizeof(protocol_name), "binance-websocket-%d", index);
    ccinfo.protocol = protocol_name;

    ccinfo.ssl_connection = LCCSCF_USE_SSL;

    if (!lws_client_connect_via_info(&ccinfo))
        printf("[ERROR] Failed to connect to Binance WebSocket server\n");
    else
        printf("[INFO] Connecting to Binance WebSocket...\n");
}

void connect_to_coinbase() {
    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = "ws-feed.exchange.coinbase.com";
    ccinfo.port = 443;
    ccinfo.path = "/";
    ccinfo.host = "ws-feed.exchange.coinbase.com";
    ccinfo.origin = "ws-feed.exchange.coinbase.com";
    ccinfo.protocol = "coinbase-websocket";
    ccinfo.ssl_connection = LCCSCF_USE_SSL;

    if (!lws_client_connect_via_info(&ccinfo))
        printf("[ERROR] Failed to connect to Coinbase WebSocket server\n");
    else
        printf("[INFO] Connecting to Coinbase WebSocket...\n");
}

void connect_to_kraken() {
    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = "ws.kraken.com";
    ccinfo.port = 443;
    ccinfo.path = "/";
    ccinfo.host = "ws.kraken.com";
    ccinfo.origin = "ws.kraken.com";
    ccinfo.protocol = "kraken-websocket";
    ccinfo.ssl_connection = LCCSCF_USE_SSL;

    if (!lws_client_connect_via_info(&ccinfo))
        printf("[ERROR] Failed to connect to Kraken WebSocket server\n");
    else
        printf("[INFO] Connecting to Kraken WebSocket...\n");
}

void connect_to_bitfinex() {
    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = "api-pub.bitfinex.com";
    ccinfo.port = 443;
    ccinfo.path = "/ws/2";
    ccinfo.host = "api-pub.bitfinex.com";
    ccinfo.origin = "api-pub.bitfinex.com";
    ccinfo.protocol = "bitfinex-websocket";
    ccinfo.ssl_connection = LCCSCF_USE_SSL;

    if (!lws_client_connect_via_info(&ccinfo))
        printf("[ERROR] Failed to connect to Bitfinex WebSocket server\n");
    else
        printf("[INFO] Connecting to Bitfinex WebSocket...\n");
}

void connect_to_huobi(int index) {
    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = "api.huobi.pro";
    ccinfo.port = 443;
    ccinfo.path = "/ws";
    ccinfo.host = "api.huobi.pro";
    ccinfo.origin = "api.huobi.pro";
    
    static char protocol_name[32];
    snprintf(protocol_name, sizeof(protocol_name), "huobi-websocket-%d", index);
    ccinfo.protocol = protocol_name;

    ccinfo.ssl_connection = LCCSCF_USE_SSL;

    if (!lws_client_connect_via_info(&ccinfo))
        printf("[ERROR] Failed to connect to Huobi WebSocket [%s]\n", protocol_name);
    else
        printf("[INFO] Connecting to Huobi WebSocket [%s]...\n", protocol_name);
}

void connect_to_okx(int index) {
    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = "ws.okx.com";
    ccinfo.port = 8443;
    ccinfo.path = "/ws/v5/public";
    ccinfo.host = "ws.okx.com";
    ccinfo.origin = "ws.okx.com";

    static char protocol_name[32];
    snprintf(protocol_name, sizeof(protocol_name), "okx-websocket-%d", index);
    ccinfo.protocol = protocol_name;


    ccinfo.ssl_connection = LCCSCF_USE_SSL;

    if (!lws_client_connect_via_info(&ccinfo))
        printf("[ERROR] Failed to connect to OKX WebSocket server\n");
    else
        printf("[INFO] Connecting to OKX WebSocket...\n");
}
