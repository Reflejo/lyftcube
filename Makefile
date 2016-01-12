CC 			= gcc
SUDO		= /usr/bin/sudo
CFLAGS 		= -Wall -O3 -std=gnu99
LDFLAGS 	= -lbcm2835 -lm -lgif
HEADERS 	= GPIO.h animation.h parser.h
EXECUTABLE 	= lyftcube
SOURCES 	= lyftcube.c GPIO.c animation.c parser.c
OBJECTS 	= $(SOURCES:.c=.o)

all: $(EXECUTABLE) permissions lyftcube-server

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

$(EXECUTABLE):: $(OBJECTS) $(HEADERS)
	$(CC) -o $@ $^ $(LDFLAGS)

permissions: 
	$(SUDO) chown root $(EXECUTABLE)
	$(SUDO) chmod 4750 $(EXECUTABLE)

lyftcube-server: lyftcube-server.c
	$(CC) -o $@ $^ $(CFLAGS) -lasyncd -lssl -levent -lqlibc -levent_openssl -D_FILE_OFFSET_BITS=64

clean:
	rm -rf *.o lyftcube-server $(EXECUTABLE)
