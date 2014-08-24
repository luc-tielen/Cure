#ifndef ELIXIR_COMM_H
#define ELIXIR_COMM_H

#define MAX_BUFFER_SIZE 65535

typedef unsigned char byte;

int read_input(byte *buffer, int length);
int read_msg(byte *buffer);
void send_msg(byte *buffer, int length);

#endif
