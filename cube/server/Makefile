CC 			= gcc
CFLAGS 		= -Wall -O3 -std=gnu99 -D_FILE_OFFSET_BITS=64
LDFLAGS 	= -lasyncd -lssl -levent -lqlibc -levent_openssl
HEADERS 	= endpoints.h
EXECUTABLE 	= lyftcube-server
SOURCES 	= lyftcube-server.c endpoints.c
OBJECTS 	= $(SOURCES:.c=.o)

all: $(EXECUTABLE)

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

$(EXECUTABLE):: $(OBJECTS) $(HEADERS)
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -rf *.o $(EXECUTABLE)
