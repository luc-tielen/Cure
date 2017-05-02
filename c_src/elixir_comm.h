#ifndef ELIXIR_COMM_H
#define ELIXIR_COMM_H
#include <stdint.h>  // uint16_t
#include <stdlib.h>  // ssize_t

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_BUFFER_SIZE 65535


/*
 * Reads a message coming from Erlang/Elixir from stdin.
 * Returns the number of bytes read (-1 on error), fills the buffer with data.
 */
ssize_t read_msg(char *buffer);

/*
 * Sends a message to Erlang/Elixir via stdout.
 */
void send_msg(char *buffer, uint16_t length);

/*
 * Helper function to send an error message back to Erlang/Elixir.
 * The message has to be a string that terminates with \0.
 */
void send_error(char *error_message);


#ifdef __cplusplus
}
#endif

#endif

