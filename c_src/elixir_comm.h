#ifndef ELIXIR_COMM_H
#define ELIXIR_COMM_H

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_BUFFER_SIZE 65535

typedef unsigned char byte;

/*
 * Reads a message coming from Erlang/Elixir from stdin.
 * Returns the number of bytes read (-1 on error), fills the buffer with data.
 */
int read_msg(char* buffer);

/*
 * Sends a message to Erlang/Elixir via stdout.
 */
void send_msg(char* buffer, int length);

/*
 * Helper function to send an error message back to Erlang/Elixir.
 * The message has to be a string that terminates with \0.
 */
void send_error(char* error_message);


#ifdef __cplusplus
}
#endif

#endif
