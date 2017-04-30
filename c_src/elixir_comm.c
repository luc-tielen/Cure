//Code mostly based on: http://www.erlang.org/doc/tutorial/c_port.html
#include <string.h>
#include <unistd.h>
#include "elixir_comm.h"

#define STDIN  0
#define STDOUT 1

/*
 * Helper function to read data from Erlang/Elixir from stdin.
 * Returns the number of bytes read (-1 on error), fills buffer with data.
 */
static int read_input(char* buffer, int length)
{
    int bytes_read = read(STDIN, buffer, length);
    if(bytes_read != length){
        return -1;
    }

    return bytes_read;
}

int read_msg(char* buffer)
{
    byte len[2]; //first 2 bytes contain length of the message.
    int length;

    if(read_input((char*)len, 2) != 2){
        return -1;
    }

    length = (len[0] << 8) | len[1];
    return read_input(buffer, length);
}

void send_msg(char* buffer, int length)
{
    byte len[2]; //first 2 bytes contain length of the message.
    len[0] = (length >> 8) & 0xff;
    len[1] = length & 0xff;
    write(STDOUT, len, 2);
    write(STDOUT, buffer, length);
}

void send_error(char* error_message)
{
    send_msg(error_message, strlen(error_message));
}
