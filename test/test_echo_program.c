#include <elixir_comm.h>

int main(void)
{
    int bytes_read;
    byte buffer[MAX_BUFFER_SIZE];
    
    while((bytes_read = read_msg(buffer)) > 0)
    {
        send_msg(buffer, bytes_read); //Simply echo data back.
    }

    return 0;
}
