/*
 * Exchange Reconnection Handler
 * 
 * This module monitors WebSocket health for each exchange and manages reconnection logic
 * using retry counters and time-based checks to maintain stable data streams.
 * 
 * Features:
 *  - Tracks last message timestamp per exchange.
 *  - Performs reconnection with retry backoff on data loss or disconnection.
 *  - Runs a background health-check thread to ensure real-time connectivity.
 * 
 * Dependencies:
 *  - Standard C libraries (stdio, string, time, unistd, pthread).
 * 
 * Usage:
 *  - Called by `exchange_websocket.c` when connections drop or time out.
 *  - Relies on `exchange_connect.c` to reinitiate WebSocket sessions.
 * 
 * Created: 3/11/2025
 * Updated: 5/8/2025
 */

 #include "exchange_reconnect.h"
 #include "exchange_connect.h"
 
 #include <stdio.h>
 #include <string.h>
 #include <unistd.h>
 #include <stdlib.h>
 #include <time.h>
 #include <pthread.h>
 
 #define NO_DATA_TIMEOUT 60              // seconds without data before reconnect
 #define HEALTH_CHECK_INTERVAL 30        // interval between health checks (seconds)
 
 /* Track retry count for each exchange */
 ExchangeRetry retry_counts[MAX_EXCHANGES] = {
     {"binance-websocket-0", 0},
     {"binance-websocket-1", 0},
     {"binance-websocket-2", 0},
     {"binance-websocket-3", 0},
     {"binance-websocket-4", 0},
     {"binance-websocket-5", 0},
     {"coinbase-websocket", 0},
     {"kraken-websocket", 0},
     {"bitfinex-websocket", 0},
     {"huobi-websocket-0", 0},
     {"huobi-websocket-1", 0},
     {"huobi-websocket-2", 0},
     {"huobi-websocket-3", 0},
     {"huobi-websocket-4", 0},
     {"huobi-websocket-5", 0},
     {"huobi-websocket-6", 0},
     {"huobi-websocket-7", 0},
     {"huobi-websocket-8", 0},
     {"huobi-websocket-9", 0},
     {"huobi-websocket-10", 0},
     {"huobi-websocket-11", 0},
     {"huobi-websocket-12", 0},
     {"huobi-websocket-13", 0},
     {"huobi-websocket-14", 0},
     {"huobi-websocket-15", 0},
     {"huobi-websocket-16", 0},
     {"huobi-websocket-17", 0},
     {"huobi-websocket-18", 0},
     {"huobi-websocket-19", 0},
     {"okx-websocket-0", 0},
     {"okx-websocket-1", 0},
     {"okx-websocket-2", 0},
     {"okx-websocket-3", 0},
     {"okx-websocket-4", 0},
     {"okx-websocket-5", 0},
     {"okx-websocket-6", 0},
     {"okx-websocket-7", 0}
 };
 
 /* Background monitor thread */
 pthread_t health_check_thread;

 time_t last_message_time[MAX_EXCHANGES] = {0};
 
 /* Find retry count index for an exchange */
 int get_exchange_index(const char *exchange) {
     for (int i = 0; i < MAX_EXCHANGES; i++) {
         if (strcmp(retry_counts[i].exchange, exchange) == 0) {
             return i;
         }
     }
     return -1;
 }
 
 /* Schedule reconnection with per-exchange retry count */
 void schedule_reconnect(const char *exchange) {
     int index = get_exchange_index(exchange);
     if (index == -1) {
         printf("[ERROR] Unknown exchange: %s\n", exchange);
         return;
     }
 
     int wait_time = retry_counts[index].retry_count;
     if (wait_time > 10) wait_time = 10;
 
     printf("[INFO] Attempting to reconnect to %s in %d seconds...\n", exchange, wait_time);
     sleep(wait_time);
     retry_counts[index].retry_count++;
 
    if (strncmp(exchange, "binance-websocket-", 18) == 0) {
        int chunk_index_binance = atoi(exchange + 18);
        connect_to_okx(chunk_index_binance);
     } else if (strcmp(exchange, "coinbase-websocket") == 0) {
         connect_to_coinbase();
     } else if (strcmp(exchange, "kraken-websocket") == 0) {
         connect_to_kraken();
     } else if (strcmp(exchange, "bitfinex-websocket") == 0) {
         connect_to_bitfinex();
     } else if (strncmp(exchange, "huobi-websocket-", 17) == 0) {
         int chunk_index_huobi = atoi(exchange + 17);
         connect_to_huobi(chunk_index_huobi);
     } else if (strncmp(exchange, "okx-websocket-", 15) == 0) {
         int chunk_index_okx = atoi(exchange + 15);
         connect_to_okx(chunk_index_okx);
     }
 }
 
 /* Monitor thread to detect no-data timeouts */
 void* monitor_exchange_health(void *arg) {
    (void)arg;
     while (1) {
         time_t now = time(NULL);
         for (int i = 0; i < MAX_EXCHANGES; i++) {
             if (last_message_time[i] == 0) continue;
 
             if (now - last_message_time[i] > NO_DATA_TIMEOUT) {
                 printf("[WARNING] No data from %s in %ld seconds. Reconnecting...\n",
                        retry_counts[i].exchange, now - last_message_time[i]);
 
                 schedule_reconnect(retry_counts[i].exchange);
                 last_message_time[i] = now;
             }
         }
         sleep(HEALTH_CHECK_INTERVAL);
     }
     return NULL;
 }
 
 /* Start background health monitor */
 void start_health_monitor() {
     if (pthread_create(&health_check_thread, NULL, monitor_exchange_health, NULL) != 0) {
         fprintf(stderr, "[ERROR] Failed to start exchange health monitor thread\n");
     } else {
         printf("[INFO] Exchange health monitor thread started\n");
     }
 } 