//Code mostly based on: http://www.erlang.org/doc/tutorial/c_port.html
#include <stdio.h>
#include "elixir_comm.h"

int read_input(byte *buffer, int length)
{
    int bytes_read = fread(buffer, sizeof(byte), length, stdin);
    if(bytes_read != length){
        return -1;
    }

    return bytes_read;
}

int read_msg(byte *buffer)
{
    byte len[2];
    int length;

    if(read_input(len, 2) != 2){
        return -1; 
    }

    length = (len[0] << 8) | len[1];
    return read_input(buffer, length);
}

void send_msg(byte *buffer, int length)
{
    byte len[2];
    len[0] = (length >> 8) & 0xff;
    len[1] = length & 0xff;
    fwrite(len, sizeof(byte), 2, stdout);
    fwrite(buffer, sizeof(byte), length, stdout);
    fflush(stdout);
}