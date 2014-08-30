#ifndef ELIXIR_COMM_H
#define ELIXIR_COMM_H

#define MAX_BUFFER_SIZE 65535

typedef unsigned char byte;

/*
 * Helper function to read data from Erlang/Elixir from stdin.
 * Returns the number of bytes read (-1 on error), fills buffer with data.
 */
static int read_input(byte* buffer, int length);

/*
 * Reads a message coming from Erlang/Elixir from stdin.
 * Returns the number of bytes read (-1 on error), fills the buffer with data.
 */
int read_msg(byte* buffer);

/*
 * Sends a message to Erlang/Elixir via stdout.
 */
void send_msg(byte* buffer, int length);

/*
 * Helper function to send an error message back to Erlang/Elixir.
 * The message has to be a string that terminates with \0.
 */
void send_error(char* error_message);

#endif
