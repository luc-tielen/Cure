INC_PARAMS=../c_src/
ELIXIR_COMM_C=$(INC_PARAMS)elixir_comm.c
WARNINGS=-Wall -Wextra -pedantic
CFLAGS=-O3

test_echo_program:
	gcc -o test_echo_program test_echo_program.c $(ELIXIR_COMM_C) \
		-I$(INC_PARAMS) ${CFLAGS} ${WARNINGS}

clean:
	rm test_echo_program

.PHONY: test_echo_program clean

